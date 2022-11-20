import AVFoundation

class HLSInterstitialAssetResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    // We keep reference to any client set AVAssetResourceLoaderDelegate to forward on events we don't handle
    weak var clientSetResourceLoaderDelegate: AVAssetResourceLoaderDelegate?
    // This is the communication point to the consumer for ad decisions
    var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler? {
        get { playlistLoader.decisionHandler }
        set { playlistLoader.decisionHandler = newValue }
    }
    
    let playlistLoader: HLSInterstitialPlaylistLoader

    init(playlistLoader: HLSInterstitialPlaylistLoader = HLSInterstitialPlaylistLoader()) {
        self.playlistLoader = playlistLoader
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest
    ) -> Bool {
        return clientSetResourceLoaderDelegate?.resourceLoader?(
            resourceLoader,
            shouldWaitForRenewalOfRequestedResource: renewalRequest
        ) ?? false
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        if let url = loadingRequest.request.url, url.isInterstitialURL() {
            if url.isAssetListURL {
                playlistLoader.loadAssetListResponse(url: url) { result in
                    switch result {
                    case .success(let assetListData):
                        loadingRequest.dataRequest?.respond(with: assetListData)
                        loadingRequest.finishLoading()
                    case .failure(let error):
                        loadingRequest.finishLoading(with: error)
                    }
                }
                return true
            }
            playlistLoader.loadPlaylist(forRequest: loadingRequest.request, interstitialURL: url) { result in
                switch result {
                case .success(let playlistData):
                    loadingRequest.dataRequest?.respond(with: playlistData)
                    loadingRequest.finishLoading()
                case .failure(let error):
                    loadingRequest.finishLoading(with: error)
                }
            }
            return true
        }
        return clientSetResourceLoaderDelegate?.resourceLoader?(
            resourceLoader,
            shouldWaitForLoadingOfRequestedResource: loadingRequest
        ) ?? false
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge
    ) -> Bool {
        return clientSetResourceLoaderDelegate?.resourceLoader?(
            resourceLoader,
            shouldWaitForResponseTo: authenticationChallenge
        ) ?? false
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel authenticationChallenge: URLAuthenticationChallenge
    ) {
        clientSetResourceLoaderDelegate?.resourceLoader?(
            resourceLoader,
            didCancel: authenticationChallenge
        )
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        // TODO - SHOULD HANDLE CANCELLING HERE AS WELL
        clientSetResourceLoaderDelegate?.resourceLoader?(
            resourceLoader,
            didCancel: loadingRequest
        )
    }
}
