import Foundation

public protocol HLSInterstitialAssetEventObserverDelegate: AnyObject {
    func interstitialAssetEventObserver(
        _ observer: HLSInterstitialAssetEventObserver,
        shouldWaitForLoadingOfRequest request: HLSInterstitialEventLoadingRequest
    ) -> Bool
}

public class HLSInterstitialAssetEventObserver {
    public weak var delegate: HLSInterstitialAssetEventObserverDelegate?
    public weak private(set) var asset: HLSInterstitialAsset?
    
    public init(asset: HLSInterstitialAsset) {
        self.asset = asset
        asset.add(observer: self)
    }
    
    func shouldWaitForLoadingOfRequest(_ request: HLSInterstitialEventLoadingRequest) -> Bool {
        return delegate?.interstitialAssetEventObserver(self, shouldWaitForLoadingOfRequest: request) ?? false
    }
}
