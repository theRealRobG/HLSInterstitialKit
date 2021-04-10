import Foundation

public struct UnexpectedEmptyResponseErrorDetails {
    public let requestURL: URL
    
    public init(requestURL: URL) {
        self.requestURL = requestURL
    }
}
