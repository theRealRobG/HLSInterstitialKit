import Foundation

public struct RequestErrorDetails {
    public let error: Error
    public let requestURL: URL
    public let statusCode: Int?
    
    public init(
        error: Error,
        requestURL: URL,
        statusCode: Int?
    ) {
        self.error = error
        self.requestURL = requestURL
        self.statusCode = statusCode
    }
}
