import Foundation

public protocol HLSInterstitialAssetDelegate: AnyObject {
    func interstitialAsset(
        _ asset: HLSInterstitialAsset,
        shouldWaitForLoadingOfRequest request: HLSInterstitialEventLoadingRequest
    ) -> Bool
}
