import Foundation

public struct PlaylistParseError: Error {
    public let underlyingError: Error
    public let code: HLSInterstitialError.Code = .playlistParseParserError
    public var description: String { "Playlist parse failed with error: \(underlyingError.localizedDescription)" }
    
    var userInfo: [String: Any] {
        [NSUnderlyingErrorKey: underlyingError]
    }
    
    public init(_ underlyingError: Error) {
        self.underlyingError = underlyingError
    }
}
