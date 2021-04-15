import Foundation

extension URL {
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
