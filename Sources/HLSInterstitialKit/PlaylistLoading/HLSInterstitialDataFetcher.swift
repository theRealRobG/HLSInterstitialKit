import Foundation

class HLSInterstitialDataFetcher {
    struct SuccessfulResponse {
        let data: Data?
        let statusCode: Int?
    }
    
    let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func loadData(forURL url: URL, completion: @escaping (Result<SuccessfulResponse, HLSInterstitialError>) -> Void) {
        var request = URLRequest(url: url)
        request.networkServiceType = .avStreaming
        urlSession.dataTask(with: request) { data, response, error in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            if let error = error {
                let requestErrorDetails = RequestErrorDetails(
                    error: error,
                    requestURL: url,
                    statusCode: statusCode
                )
                return completion(.failure(.networkError(.requestError(requestErrorDetails))))
            }
            completion(.success(SuccessfulResponse(data: data, statusCode: statusCode)))
        }.resume()
    }
}
