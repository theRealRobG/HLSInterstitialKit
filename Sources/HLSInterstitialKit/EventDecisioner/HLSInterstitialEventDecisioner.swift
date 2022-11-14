import mamba

protocol EventDecisioner {
    func events(
        forParameters parameters: [String: HLSInterstitialEventLoadingRequest.Parameters],
        playlist: HLSPlaylist
    ) async -> EventsResponse
}

struct EventsResponse {
    let idToEventMap: [String: HLSInterstitialEvent]
    let preRollInterstitials: [HLSInterstitialEvent]
    let initialInterstitials: [HLSInterstitialInitialEvent]
}

/// Provides a wrapper around the decisioning actor
///
/// Since we need to keep a single reference for event decisions across all media playlists, and actors are value types,
/// we need to wrap the actor in a reference type in order to provide the same actor for all media decisions.
class HLSInterstitialEventDecisioner: EventDecisioner {
    weak var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler?

    private let decisioningActor: HLSInterstitialEventDecisioningActor
    private let requestHandler: RequestDecisionHandler

    init() {
        let requestHandler = RequestDecisionHandler()
        self.decisioningActor = HLSInterstitialEventDecisioningActor(decisionHandler: requestHandler)
        self.requestHandler = requestHandler
        requestHandler.decisionHandler = self
    }

    func events(
        forParameters parameters: [String: HLSInterstitialEventLoadingRequest.Parameters],
        playlist: HLSPlaylist
    ) async -> EventsResponse {
        await decisioningActor.events(forParameters: parameters, playlist: playlist)
    }
}

// This is a little silly, but because the decisioning actor is an actor, meaning its properties are only accessible
// asynchrounously, it is hard to proxy the delegate methods through as we do elsewhere. As a result, we allow for
// setting the delegate through the initializer; however, we can't set the decisioner as the delegate as it would not be
// fully initialized when trying to set self as delegate. So there is this strange dance here where we create a proxy
// class just to transfer delegate methods between the actor and the container.
extension HLSInterstitialEventDecisioner: HLSInterstitialEventLoadingRequestDecisionHandler {
    class RequestDecisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler {
        weak var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler?

        func shouldWaitForLoadingOfRequest(_ request: HLSInterstitialEventLoadingRequest) -> Bool {
            guard let decisionHandler = decisionHandler else { return false }
            return decisionHandler.shouldWaitForLoadingOfRequest(request)
        }

        func shouldWaitForLoadingOfInitialRequest(_ request: HLSInterstitialEventInitialLoadingRequest) -> Bool {
            guard let decisionHandler = decisionHandler else { return false }
            return decisionHandler.shouldWaitForLoadingOfInitialRequest(request)
        }
    }

    func shouldWaitForLoadingOfRequest(_ request: HLSInterstitialEventLoadingRequest) -> Bool {
        guard let decisionHandler = decisionHandler else { return false }
        return decisionHandler.shouldWaitForLoadingOfRequest(request)
    }

    func shouldWaitForLoadingOfInitialRequest(_ request: HLSInterstitialEventInitialLoadingRequest) -> Bool {
        guard let decisionHandler = decisionHandler else { return false }
        return decisionHandler.shouldWaitForLoadingOfInitialRequest(request)
    }
}
