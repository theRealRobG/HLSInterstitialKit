import Foundation

public struct UnexpectedEmptyResponseErrorDetails {
    public let requestURL: URL
    public let responseStatusCode: Int?
    
    public init(
        requestURL: URL,
        responseStatusCode: Int?
    ) {
        self.requestURL = requestURL
        self.responseStatusCode = responseStatusCode
    }
}
