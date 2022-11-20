import Foundation

extension URL {
    /// Base URL for X-ASSET-LIST
    static let assetListBaseURL = URL(string: "https://asset-list/assets.json")!.toInterstitialURL()

    /// Helper to determne whether this `URL` is an X-ASSET-LIST URL
    var isAssetListURL: Bool {
        if #available(iOS 16, tvOS 16, *) {
            return isInterstitialURL() && host() == "asset-list" && path() == "/assets.json"
        } else {
            return isInterstitialURL() && host == "asset-list" && path == "/assets.json"
        }
    }

    /// The value of the `_HLS_interstitial_id` query parameter (if it exists)
    var hlsInterstitialId: String? {
        URLComponents(url: self, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "_HLS_interstitial_id" })?
            .value
    }

    /// Helper method to determine whether this `URL` is a `HLSInterstitialScheme` type of `URL`.
    func isInterstitialURL() -> Bool {
        guard let scheme = scheme else { return false }
        return HLSInterstitialScheme(rawValue: scheme) != nil
    }
    
    /// Helper method that defaults to no-op if not a `HLSInterstitialScheme` type of `URL`.
    func fromInterstitialURL() -> URL {
        guard let scheme = scheme, let interstitialScheme = HLSInterstitialScheme(rawValue: scheme) else { return self }
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return self }
        urlComponents.scheme = HTTPScheme(hlsInterstitialScheme: interstitialScheme).rawValue
        return urlComponents.url ?? self
    }
    
    /// Helper method that defaults to no-op if not a `HTTPScheme` type of `URL`.
    func toInterstitialURL() -> URL {
        guard let scheme = scheme, let httpScheme = HTTPScheme(rawValue: scheme) else { return self }
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return self }
        urlComponents.scheme = HLSInterstitialScheme(httpScheme: httpScheme).rawValue
        return urlComponents.url ?? self
    }
}
