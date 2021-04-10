enum HTTPScheme: String {
    case http
    case https

    init(hlsInterstitialScheme: HLSInterstitialScheme) {
        switch hlsInterstitialScheme {
        case .hlsinterstitialhttp:
            self = .http
        case .hlsinterstitialhttps:
            self = .https
        }
    }

    init?(hlsInterstitialScheme: HLSInterstitialScheme?) {
        guard let scheme = hlsInterstitialScheme else { return nil }
        self = HTTPScheme(hlsInterstitialScheme: scheme)
    }
}
