import Foundation

public protocol HLSInterstitialAssetDelegate: AnyObject {
    /// Asks the delegate if it wants to handle the request.
    ///
    /// The asset calls this method when assistance is required of your code to load the potential interstitial event.
    /// For example, the asset might call this method when an EXT-X-DATERANGE tag is found in the playlist, with
    /// SCTE35-OUT attribute having valid SCTE-35 information that potentially indicates an ad insertion opportunity.
    ///
    /// Each interstitial event request parameters will only ever be requested for loading once.
    ///
    /// Returning `true` from this method, implies only that the receiver will load, or at least attempt to load, the
    /// interstitial event information. In some implementations, the actual work of loading the resource might be
    /// initiated on another thread, running asynchronously to the asset delegate; whether the work begins immediately
    /// or merely soon is an implementation detail of the client application.
    ///
    /// You can load the resource synchronously or asynchronously. In both cases, you must indicate success or failure
    /// of the operation by calling the finishLoading(withResult:) or cancel() method of the request object when you
    /// finish.
    ///
    /// **NOTE:** If loading synchronously, do not use `DispatchSemaphore`, as internally the `HLSInterstitialAsset` is
    /// making use of Swift Concurrency while waiting for responses, which does not function well with semaphores.
    ///
    /// If you return `false` from this method, the asset treats the loading of request parameters as having failed.
    /// - Parameters:
    ///   - asset: The asset making the request.
    ///   - request: The request object that contains information about the requested event parameters.
    /// - Returns: `true` if your delegate can load the resource specified by the loadingRequest parameter or `false` if
    /// it cannot.
    func interstitialAsset(
        _ asset: HLSInterstitialAsset,
        shouldWaitForLoadingOfRequest request: HLSInterstitialEventLoadingRequest
    ) -> Bool

    /// Asks the delegate if it wants to handle the first request.
    ///
    /// This method is much the same as `interstitialAsset(_:shouldWaitForLoadingOfRequest)`, except that this request
    /// is only ever made once at the start of playback, and is where the application code can provide pre-roll
    /// interstitial events or manually timed interstitial events (not constrained to an EXT-X-DATERANGE tag). The
    /// `request.playlist` parameter can provide additional context on what playlist the insertion is being made into.
    ///
    /// Returning `true` from this method, implies only that the receiver will load, or at least attempt to load, the
    /// interstitial event information. In some implementations, the actual work of loading the resource might be
    /// initiated on another thread, running asynchronously to the asset delegate; whether the work begins immediately
    /// or merely soon is an implementation detail of the client application.
    ///
    /// You can load the resource synchronously or asynchronously. In both cases, you must indicate success or failure
    /// of the operation by calling the finishLoading(withResult:) or cancel() method of the request object when you
    /// finish.
    ///
    /// **NOTE:** If loading synchronously, do not use `DispatchSemaphore`, as internally the `HLSInterstitialAsset` is
    /// making use of Swift Concurrency while waiting for responses, which does not function well with semaphores.
    ///
    /// If you return `false` from this method, the asset treats the loading of request parameters as having failed.
    /// - Parameters:
    ///   - asset: The asset making the request.
    ///   - request: The request object that contains information about the requested event parameters.
    /// - Returns: `true` if your delegate can load the resource specified by the loadingRequest parameter or `false` if
    /// it cannot.
    func interstitialAsset(
        _ asset: HLSInterstitialAsset,
        shouldWaitForLoadingOfInitialRequest request: HLSInterstitialEventInitialLoadingRequest
    ) -> Bool
}
