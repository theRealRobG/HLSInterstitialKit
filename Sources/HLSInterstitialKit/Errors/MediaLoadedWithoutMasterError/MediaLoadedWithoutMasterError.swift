import Foundation

public struct MediaLoadedWithoutMasterError: Error {
    public let code: HLSInterstitialError.Code = .mediaLoadedWithoutMasterError
    public let description = "Media playlist loaded without a master playlist for reference."
    public let playlistURL: URL
    
    var userInfo: [String: Any] {
        [HLSInterstitialError.RequestURLUserInfoKey: playlistURL]
    }
    
    public init(playlistURL: URL) {
        self.playlistURL = playlistURL
    }
}
