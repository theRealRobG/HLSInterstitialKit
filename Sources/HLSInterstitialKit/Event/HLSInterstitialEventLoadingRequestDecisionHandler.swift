protocol HLSInterstitialEventLoadingRequestDecisionHandler: AnyObject {
    func shouldWaitForLoadingOfRequest(_ request: HLSInterstitialEventLoadingRequest) -> Bool
    func shouldWaitForLoadingOfInitialRequest(_ request: HLSInterstitialEventInitialLoadingRequest) -> Bool
}
