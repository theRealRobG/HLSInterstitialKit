import Foundation

enum HLSInterstitialScheme: String {
    case hlsinterstitialhttp
    case hlsinterstitialhttps
    
    init(httpScheme: HTTPScheme) {
        switch httpScheme {
        case .http:
            self = .hlsinterstitialhttp
        case .https:
            self = .hlsinterstitialhttps
        }
    }
    
    init?(httpScheme: HTTPScheme?) {
        guard let scheme = httpScheme else { return nil }
        self = HLSInterstitialScheme(httpScheme: scheme)
    }
}
