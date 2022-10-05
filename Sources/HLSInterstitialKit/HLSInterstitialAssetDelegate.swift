import Foundation

public protocol HLSInterstitialAssetDelegate: AnyObject {
    func interstitialAssetEventObserver(
        _ asset: HLSInterstitialAsset,
        shouldWaitForLoadingOfRequest request: HLSInterstitialEventLoadingRequest
    ) -> Bool
}
