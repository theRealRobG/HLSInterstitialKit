import Foundation

public enum HLSInterstitialError: LocalizedError, CustomNSError {
    case networkError(NetworkError)
    case playlistParseError(PlaylistParseError)
    case mediaLoadedWithoutMasterError(MediaLoadedWithoutMasterError)
    
    public static let errorDomain = "HLSInterstitialError"
    public static let RequestURLUserInfoKey = "HLSInterstitialError.RequestURLUserInfoKey"
    public static let NetworkErrorStatusCodeUserInfoKey = "HLSInterstitialError.NetworkErrorStatusCodeUserInfoKey"
    
    public var errorCode: Int {
        switch self {
        case .networkError(let error): return error.code.rawValue
        case .playlistParseError(let error): return error.code.rawValue
        case .mediaLoadedWithoutMasterError(let error): return error.code.rawValue
        }
    }
    
    public var errorUserInfo: [String: Any] {
        switch self {
        case .networkError(let error): return error.userInfo
        case .playlistParseError(let error): return error.userInfo
        case .mediaLoadedWithoutMasterError(let error): return error.userInfo
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error): return error.description
        case .playlistParseError(let error): return error.description
        case .mediaLoadedWithoutMasterError(let error): return error.description
        }
    }
}

public extension HLSInterstitialError {
    enum Code: Int {
        // Network errors
        case networkRequestError = 100
        case networkUnexpectedEmptyResponse = 101
        // Playlist parse errors
        case playlistParseParserError = 200
        // Media load errors
        case mediaLoadedWithoutMasterError = 300
    }
}
