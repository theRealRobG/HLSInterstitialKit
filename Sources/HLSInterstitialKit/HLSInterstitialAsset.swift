import Foundation
import AVFoundation

public final class HLSInterstitialAsset: AVURLAsset {
    public weak var delegate: HLSInterstitialAssetDelegate?

    private let originalURL: URL
    private let defaultResourceLoaderDelegateQueue = DispatchQueue(
        label: "com.hlsinterstitialkit.hlsinterstitialasset.default-resource-loader-delegate-queue",
        qos: .userInteractive
    )
    private let resourceLoaderDelegate: HLSInterstitialAssetResourceLoaderDelegate
    
    public override init(url: URL, options: [String: Any]? = nil) {
        self.originalURL = url
        self.resourceLoaderDelegate = HLSInterstitialAssetResourceLoaderDelegate()
        super.init(url: url.toInterstitialURL(), options: options)
        // We set the asset as the ad decision delegate for any ad decisions needed from the playlist
        self.resourceLoaderDelegate.decisionHandler = self
        // We set our own resourceLoader.delegate to handle HLSInterstitialScheme URL requests for manifest manipulation
        resourceLoader.setDelegate(resourceLoaderDelegate, queue: defaultResourceLoaderDelegateQueue)
        // We listen for changes to the resourceLoader.delegate to ensure our delegate is always set
        resourceLoader.addObserver(
            self,
            forKeyPath: #keyPath(AVAssetResourceLoader.delegate),
            options: .new,
            context: nil
        )
    }
    
    public convenience init(
        url: URL,
        options: [String : Any]? = nil,
        initialEvents: [HLSInterstitialInitialEvent],
        preRollInterstitials: [HLSInterstitialEvent]
    ) {
        self.init(url: url, options: options)
        resourceLoaderDelegate.initialEvents = initialEvents
        resourceLoaderDelegate.preRollInterstitials = preRollInterstitials
    }
    
    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == #keyPath(AVAssetResourceLoader.delegate) else { return }
        guard resourceLoader.delegate === resourceLoaderDelegate else {
            // Update the delegate that the client has set
            resourceLoaderDelegate.clientSetResourceLoaderDelegate = resourceLoader.delegate
            // We also update to using the queue that the client has specified
            resourceLoader.setDelegate(resourceLoaderDelegate, queue: resourceLoader.delegateQueue)
            return
        }
    }
}

extension HLSInterstitialAsset: HLSInterstitialEventLoadingRequestDecisionHandler {
    func shouldWaitForLoadingOfRequest(_ request: HLSInterstitialEventLoadingRequest) -> Bool {
        return delegate?.interstitialAsset(self, shouldWaitForLoadingOfRequest: request) ?? false
    }
}
