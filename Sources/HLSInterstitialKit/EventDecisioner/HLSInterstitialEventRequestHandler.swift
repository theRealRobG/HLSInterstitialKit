import mamba

actor HLSInterstitialEventRequestHandler: HLSInterstitialEventLoadingRequestDelegate {
    private weak var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler?
    private let isInitialRequest: Bool
    private var loadingRequests = [
        HLSInterstitialEventLoadingRequest: CheckedContinuation<ParameterizedEvents, Never>
    ]()

    init(
        decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler?,
        isInitialRequest: Bool
    ) {
        self.decisionHandler = decisionHandler
        self.isInitialRequest = isInitialRequest
    }

    func events(
        forParameters parameters: [HLSInterstitialEventLoadingRequest.Parameters],
        playlist: HLSPlaylist
    ) async -> ParameterizedEvents {
        guard let decisionHandler = decisionHandler else { return emptyResponse(fromParameters: parameters) }
        if parameters.isEmpty && !isInitialRequest {
            return emptyResponse(fromParameters: parameters)
        }
        if isInitialRequest {
            let eventRequest = HLSInterstitialEventInitialLoadingRequest(
                parameters: parameters,
                playlist: playlist,
                delegate: self
            )
            return await withCheckedContinuation { continuation in
                Task {
                    loadingRequests[eventRequest] = continuation
                    guard decisionHandler.shouldWaitForLoadingOfInitialRequest(eventRequest) else {
                        loadingRequestCancelled(request: eventRequest)
                        return
                    }
                }
            }
        } else {
            let eventRequest = HLSInterstitialEventLoadingRequest(
                parameters: parameters,
                playlist: playlist,
                delegate: self
            )
            return await withCheckedContinuation { continuation in
                Task {
                    loadingRequests[eventRequest] = continuation
                    guard decisionHandler.shouldWaitForLoadingOfRequest(eventRequest) else {
                        loadingRequestCancelled(request: eventRequest)
                        return
                    }
                }
            }
        }
    }

    nonisolated func interstitialEventLoadingRequest(
        _ request: HLSInterstitialEventLoadingRequest,
        didFinishLoadingWithResult result: HLSInterstitialEventLoadingRequestResult,
        preRollInterstitials: [HLSInterstitialEvent],
        midRollInterstiitals: [HLSInterstitialInitialEvent]
    ) {
        Task {
            switch result {
            case .success(let events):
                await loadingRequestCompleted(
                    request: request,
                    events: events,
                    preRollInterstitials: preRollInterstitials,
                    midRollInterstiitals: midRollInterstiitals
                )
            case .failure:
                await loadingRequestCancelled(request: request)
            }
        }
    }

    nonisolated func interstitialEventLoadingRequestDidGetCancelled(_ request: HLSInterstitialEventLoadingRequest) {
        Task {
            await loadingRequestCancelled(request: request)
        }
    }

    private func loadingRequestCompleted(
        request: HLSInterstitialEventLoadingRequest,
        events: [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent?],
        preRollInterstitials: [HLSInterstitialEvent],
        midRollInterstiitals: [HLSInterstitialInitialEvent]
    ) {
        guard let continuation = loadingRequests[request] else { return }
        loadingRequests.removeValue(forKey: request)
        // Just ensuring that only requested parameters are provided by delegate, and that we have a response for each.
        let events = request.parameters.reduce(
            into: [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent?]()
        ) {
            $0[$1] = events[$1]
        }
        continuation.resume(
            returning: ParameterizedEvents(
                parameterizedEvents: events,
                preRollInterstitials: preRollInterstitials,
                midRollInterstiitals: midRollInterstiitals
            )
        )
    }

    private func loadingRequestCancelled(request: HLSInterstitialEventLoadingRequest) {
        guard let continuation = loadingRequests[request] else { return }
        loadingRequests.removeValue(forKey: request)
        continuation.resume(returning: emptyResponse(fromParameters: request.parameters))
    }

    private func emptyResponse(
        fromParameters parameters: [HLSInterstitialEventLoadingRequest.Parameters]
    ) -> ParameterizedEvents {
        let events = parameters.reduce(into: [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent?]()) {
            $0[$1] = nil
        }
        return ParameterizedEvents(
            parameterizedEvents: events,
            preRollInterstitials: [],
            midRollInterstiitals: []
        )
    }
}

extension HLSInterstitialEventRequestHandler {
    struct ParameterizedEvents {
        let parameterizedEvents: [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent?]
        let preRollInterstitials: [HLSInterstitialEvent]
        let midRollInterstiitals: [HLSInterstitialInitialEvent]
    }
}
