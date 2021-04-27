protocol HLSInterstitialEventLoadingRequestDecisionHandler: AnyObject {
    func shouldWaitForLoadingOfRequest(_ request: HLSInterstitialEventLoadingRequest) -> Bool
}
