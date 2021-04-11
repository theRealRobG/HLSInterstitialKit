import Foundation

public enum NetworkError: Error {
    public static let RequestURLUserInfoKey = "NetworkErrorRequestURLUserInfoKey"
    public static let StatusCodeUserInfoKey = "NetworkErrorStatusCodeUserInfoKey"
    
    case requestError(RequestErrorDetails)
    case unexpectedEmptyResponse(UnexpectedEmptyResponseErrorDetails)
    
    public var code: HLSInterstitialError.Code {
        switch self {
        case .requestError: return .networkRequestError
        case .unexpectedEmptyResponse: return .networkUnexpectedEmptyResponse
        }
    }
    
    public var description: String {
        switch self {
        case .requestError(let details):
            let statusCodeText = details.statusCode.map { "(HTTP Status: \($0))" } ?? "(HTTP Status: Unknown)"
            return "Request (URL: \(details.requestURL.absoluteString)) failed \(statusCodeText) with error: \(details.error.localizedDescription)"
        case .unexpectedEmptyResponse(let details):
            let statusCodeText = details.responseStatusCode.map { "(HTTP Status: \($0))" } ?? "(HTTP Status: Unknown)"
            return "Unexpected empty response \(statusCodeText) (URL: \(details.requestURL.absoluteString))"
        }
    }
    
    var userInfo: [String: Any] {
        switch self {
        case .requestError(let details):
            var info: [String: Any] = [
                NSUnderlyingErrorKey: details.error,
                Self.RequestURLUserInfoKey: details.requestURL
            ]
            if let statusCode = details.statusCode {
                info[Self.StatusCodeUserInfoKey] = statusCode
            }
            return info
        case .unexpectedEmptyResponse(let details):
            var info: [String: Any] = [
                Self.RequestURLUserInfoKey: details.requestURL
            ]
            if let statusCode = details.responseStatusCode {
                info[Self.StatusCodeUserInfoKey] = statusCode
            }
            return info
        }
    }
}
