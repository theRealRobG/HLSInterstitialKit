import Foundation
import AVFoundation

public final class HLSInterstitialAsset: AVURLAsset {
    private let originalURL: URL
    private let defaultResourceLoaderDelegateQueue = DispatchQueue(
        label: "com.csaikit.csaiasset.default-resource-loader-delegate-queue",
        qos: .userInteractive
    )
    private let resourceLoaderDelegate: HLSInterstitialAssetResourceLoaderDelegate
    
    private(set) var initialEvents = [HLSInterstitialInitialEvent]()
    
    public override init(url: URL, options: [String: Any]? = nil) {
        self.originalURL = url
        self.resourceLoaderDelegate = HLSInterstitialAssetResourceLoaderDelegate()
        super.init(url: url.toInterstitialURL(), options: options)
        // We set our own resourceLoader.delegate to handle HLSInterstitialScheme URL requests for manifest manipulation
        resourceLoader.setDelegate(resourceLoaderDelegate, queue: defaultResourceLoaderDelegateQueue)
        // We listen for changes to the resourceLoader.delegate to ensure our delegate is always set
        resourceLoader.addObserver(
            self, forKeyPath: #keyPath(AVAssetResourceLoader.delegate),
            options: .new,
            context: nil
        )
    }
    
    public convenience init(url: URL, options: [String : Any]? = nil, initialEvents: [HLSInterstitialInitialEvent]) {
        self.init(url: url, options: options)
        self.initialEvents = initialEvents
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
