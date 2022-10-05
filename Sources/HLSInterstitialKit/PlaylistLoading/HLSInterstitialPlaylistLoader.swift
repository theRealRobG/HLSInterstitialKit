import Foundation
import mamba

class HLSInterstitialPlaylistLoader {
    var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler? {
        get { mediaPlaylistManipulator.decisionHandler }
        set { mediaPlaylistManipulator.decisionHandler = newValue }
    }
    
    private let dataFetcher: HLSInterstitialDataFetcher
    private let hlsParser: HLSParser
    private let mediaPlaylistManipulator: MediaPlaylistManipulator

    init(
        dataFetcher: HLSInterstitialDataFetcher = HLSInterstitialDataFetcher(),
        hlsParser: HLSParser = HLSParser(),
        mediaPlaylistManipulator: MediaPlaylistManipulator = MediaPlaylistManipulator()
    ) {
        self.dataFetcher = dataFetcher
        self.hlsParser = hlsParser
        self.mediaPlaylistManipulator = mediaPlaylistManipulator
    }

    func loadPlaylist(
        forRequest request: URLRequest,
        interstitialURL: URL,
        initialInterstitials: [HLSInterstitialInitialEvent],
        preRollInterstitials: [HLSInterstitialEvent],
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
                preRollInterstitials: preRollInterstitials,
                completion: completion
            )
        }
    }

    func manipulate(
        playlistData originalPlaylistData: Data,
        url: URL,
        initialInterstitials: [HLSInterstitialInitialEvent],
        preRollInterstitials: [HLSInterstitialEvent],
        completion: @escaping (Result<Data, HLSInterstitialError>) -> Void
    ) {
        do {
            var playlist = try hlsParser.parse(playlistData: originalPlaylistData, url: url)

            switch playlist.type {
            case .unknown:
                completion(.success(originalPlaylistData))

            case .master:
                playlist.convertURLsToInterstitialScheme()
                let playlistData = try playlist.write()
                completion(.success(playlistData))

            case .media:
                mediaPlaylistManipulator.manipulate(
                    playlist: &playlist,
                    initialInterstitials: initialInterstitials,
                    preRollInterstitials: preRollInterstitials,
                    completion: completion
                )
                let playlistData = try playlist.write()
                completion(.success(playlistData))
            }
        } catch {
            guard let interstitialError = error as? HLSInterstitialError else {
                return completion(.failure(.playlistParseError(PlaylistParseError(error))))
            }
            completion(.failure(interstitialError))
        }
    }
}
