import Foundation
import mamba

class HLSInterstitialPlaylistLoader {
    let dataFetcher: HLSInterstitialDataFetcher
    let hlsParser: HLSParser

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
            self?.manipulate(playlistData: playlistData, url: url, completion: completion)
        }
    }

    func manipulate(playlistData originalPlaylistData: Data, url: URL, completion: @escaping (Result<Data, HLSInterstitialError>) -> Void) {
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
                playlist.convertURLsFromInterstitialScheme()
                let playlistData = try playlist.write()
                completion(.success(playlistData))
            }
        } catch {
            completion(.failure(.playlistParseError(PlaylistParseError(error))))
        }
    }
}
