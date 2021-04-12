import Foundation
import mamba

class HLSInterstitialPlaylistLoader {
    private let dataFetcher: HLSInterstitialDataFetcher
    private let hlsParser: HLSParser
    private var masterPlaylist: MasterPlaylist?

    init(
        dataFetcher: HLSInterstitialDataFetcher = HLSInterstitialDataFetcher(),
        hlsParser: HLSParser = HLSParser()
    ) {
        self.dataFetcher = dataFetcher
        self.hlsParser = hlsParser
    }

    func loadPlaylist(
        forRequest request: URLRequest,
        interstitialURL: URL,
        initialInterstitials: [HLSInterstitialInitialEvent],
        completion: @escaping (Result<Data, HLSInterstitialError>) -> Void
    ) {
        var updatedRequest = request
        let url = interstitialURL.fromInterstitialURL()
        updatedRequest.url = url
        dataFetcher.loadData(forRequest: updatedRequest, url: url) { [weak self] result in
            let playlistData: Data
            switch result {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let response):
                guard let data = response.data else {
                    let errorDetails = UnexpectedEmptyResponseErrorDetails(requestURL: url, responseStatusCode: response.statusCode)
                    return completion(.failure(.networkError(.unexpectedEmptyResponse(errorDetails))))
                }
                playlistData = data
            }
            self?.manipulate(
                playlistData: playlistData,
                url: url,
                initialInterstitials: initialInterstitials,
                completion: completion
            )
        }
    }

    func manipulate(
        playlistData originalPlaylistData: Data,
        url: URL,
        initialInterstitials: [HLSInterstitialInitialEvent],
        completion: @escaping (Result<Data, HLSInterstitialError>) -> Void
    ) {
        do {
            var playlist = try hlsParser.parse(playlistData: originalPlaylistData, url: url)

            switch playlist.type {
            case .unknown:
                completion(.success(originalPlaylistData))

            case .master:
                let masterPlaylist = MasterPlaylist(&playlist, initialInterstitials: initialInterstitials)
                self.masterPlaylist = masterPlaylist
                let playlistData = try masterPlaylist.writeMaster()
                completion(.success(playlistData))

            case .media:
                guard let masterPlaylist = masterPlaylist else {
                    throw HLSInterstitialError.mediaLoadedWithoutMasterError(
                        MediaLoadedWithoutMasterError(playlistURL: playlist.url)
                    )
                }
                masterPlaylist.updateMedia(playlist: &playlist, completion: completion)
            }
        } catch {
            guard let interstitialError = error as? HLSInterstitialError else {
                return completion(.failure(.playlistParseError(PlaylistParseError(error))))
            }
            completion(.failure(interstitialError))
        }
    }
}
