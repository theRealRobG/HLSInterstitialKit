import Foundation
import mamba

actor HLSInterstitialEventDecisioningActor: EventDecisioner {
    weak var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler?

    /// IDs that did not have adverts provided for.
    private var emptyIDs = [String]()
    /// All events mapped to their corresponding IDs.
    private var idToEventMap = [String: HLSInterstitialEvent]()
    /// All active requests
    private var activeRequests = [String: Task<Void, Never>]()
    /// The initial request is handled in a special fashion as the consumer can one-time provide pre-rolls and timed
    /// mid-roll interstitials for VOD.
    private var initialRequestStatus = InitialRequestStatus.notStarted

    init(decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler) {
        self.decisionHandler = decisionHandler
    }

    func events(
        forParameters parameters: [String: HLSInterstitialEventLoadingRequest.Parameters],
        playlist: HLSPlaylist
    ) async -> EventsResponse {
        let isInitialRequest = !initialRequestStatus.hasStarted
        if isInitialRequest {
            initialRequestStatus = .inProgress
        }
        if Set(emptyIDs).union(Set(idToEventMap.keys)).isSuperset(of: Set(parameters.keys)) && !isInitialRequest {
            return EventsResponse(idToEventMap: idToEventMap, initialRequestStatus: initialRequestStatus)
        }
        let decisionedIDs = Set(emptyIDs).union(Set(idToEventMap.keys))
        let newParameters = parameters.values.filter { !decisionedIDs.contains($0.id) }
        var tasksToAwait = [Task<Void, Never>]()
        let paramsNeedingDecision: [HLSInterstitialEventLoadingRequest.Parameters] = newParameters.compactMap {
            let id = $0.id
            if let activeRequest = activeRequests[id] {
                tasksToAwait.append(activeRequest)
                return nil
            } else {
                return $0
            }
        }
        tasksToAwait.append(
            Task {
                let eventHandler = HLSInterstitialEventRequestHandler(
                    decisionHandler: decisionHandler,
                    isInitialRequest: isInitialRequest
                )
                let events = await eventHandler.events(forParameters: paramsNeedingDecision, playlist: playlist)
                for (params, event) in events.parameterizedEvents {
                    if let event = event {
                        idToEventMap[params.id] = event
                    } else {
                        emptyIDs.append(params.id)
                    }
                }
                if isInitialRequest {
                    initialRequestStatus = .completed(
                        InitialInterstials(
                            preRollInterstitials: events.preRollInterstitials,
                            initialInterstitials: events.midRollInterstiitals
                        )
                    )
                }
            }
        )
        for task in tasksToAwait {
            await task.value
        }
        return EventsResponse(idToEventMap: idToEventMap, initialRequestStatus: initialRequestStatus)
    }
}

extension HLSInterstitialEventDecisioningActor {
    struct InitialInterstials {
        let preRollInterstitials: [HLSInterstitialEvent]
        let initialInterstitials: [HLSInterstitialInitialEvent]
    }

    enum InitialRequestStatus {
        case notStarted
        case inProgress
        case completed(InitialInterstials)

        var hasStarted: Bool {
            switch self {
            case .notStarted: return false
            case .inProgress, .completed: return true
            }
        }

        var initialInterstitials: InitialInterstials {
            switch self {
            case .notStarted, .inProgress: return InitialInterstials(preRollInterstitials: [], initialInterstitials: [])
            case .completed(let interstitials): return interstitials
            }
        }
    }
}

fileprivate extension EventsResponse {
    init(
        idToEventMap: [String: HLSInterstitialEvent],
        initialRequestStatus: HLSInterstitialEventDecisioningActor.InitialRequestStatus
    ) {
        let initialInterstitials = initialRequestStatus.initialInterstitials
        self.idToEventMap = idToEventMap
        self.preRollInterstitials = initialInterstitials.preRollInterstitials
        self.initialInterstitials = initialInterstitials.initialInterstitials
    }
}
