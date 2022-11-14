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
        completion: @escaping (Result<Data, Error>) -> Void
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
                    let errorDetails = UnexpectedEmptyResponseErrorDetails(
                        requestURL: url,
                        responseStatusCode: response.statusCode
                    )
                    return completion(
                        .failure(HLSInterstitialError.networkError(.unexpectedEmptyResponse(errorDetails)))
                    )
                }
                playlistData = data
            }
            Task { [weak self] in
                guard let self = self else { return completion(.failure(CancellationError())) }
                do {
                    let data = try await self.manipulate(
                        playlistData: playlistData,
                        url: url
                    )
                    completion(.success(data))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func manipulate(playlistData originalPlaylistData: Data, url: URL) async throws -> Data {
        do {
            var playlist = try hlsParser.parse(playlistData: originalPlaylistData, url: url)

            switch playlist.type {
            case .unknown:
                return originalPlaylistData

            case .master:
                playlist.convertURLsToInterstitialScheme()
                return try playlist.write()

            case .media:
                return try await mediaPlaylistManipulator.manipulate(playlist: &playlist)
            }
        } catch {
            guard let interstitialError = error as? HLSInterstitialError else {
                throw HLSInterstitialError.playlistParseError(PlaylistParseError(error))
            }
            throw interstitialError
        }
    }
}
