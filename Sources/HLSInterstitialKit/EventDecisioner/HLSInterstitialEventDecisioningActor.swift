import Foundation
import mamba

actor HLSInterstitialEventDecisioningActor: EventDecisioner {
    weak var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler?

    /// IDs that did not have adverts provided for.
    private var emptyIDs = [String]()
    /// All events mapped to their corresponding IDs.
    private var idToEventMap = [String: HLSInterstitialEvent]() {
        didSet { eventIdToIdMap = idToEventMap.reduce(into: [:]) { $0[$1.value.id] = $1.key } }
    }
    /// `HLSInterstitialEvent` id mapping to `EXT-X-DATERANGE:ID` to help with lookup via `X-ASSET-LIST`
    private var eventIdToIdMap = [String: String]()
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
        let isInitialRequest: Bool
        let initialRequestCompleted: Bool
        switch initialRequestStatus {
        case .notStarted:
            isInitialRequest = true
            initialRequestCompleted = false
        case .inProgress:
            isInitialRequest = false
            initialRequestCompleted = false
        case .completed:
            isInitialRequest = false
            initialRequestCompleted = true
        }
        if Set(emptyIDs).union(Set(idToEventMap.keys)).isSuperset(of: Set(parameters.keys)) && initialRequestCompleted {
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
            } else if let initialRequest = initialRequestStatus.inProgressTask {
                tasksToAwait.append(initialRequest)
                return nil
            } else {
                return $0
            }
        }
        if !paramsNeedingDecision.isEmpty || isInitialRequest {
            let task = Task {
                let eventHandler = HLSInterstitialEventRequestHandler(
                    decisionHandler: decisionHandler,
                    isInitialRequest: isInitialRequest
                )
                let events = await eventHandler.events(forParameters: paramsNeedingDecision, playlist: playlist)
                paramsNeedingDecision.forEach { activeRequests.removeValue(forKey: $0.id) }
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
            if isInitialRequest {
                initialRequestStatus = .inProgress(task)
            }
            paramsNeedingDecision.forEach { activeRequests[$0.id] = task }
            tasksToAwait.append(task)
        }
        for task in tasksToAwait {
            await task.value
        }
        return EventsResponse(idToEventMap: idToEventMap, initialRequestStatus: initialRequestStatus)
    }

    func event(forId eventId: String) async -> HLSInterstitialEvent? {
        if let id = eventIdToIdMap[eventId], let event = idToEventMap[id] {
            return event
        }
        let initialInterstitials = initialRequestStatus.initialInterstitials
        if let event = initialInterstitials.preRollInterstitials.first(where: { $0.id == eventId }) {
            return event
        } else {
            return initialInterstitials.initialInterstitials.first(where: { $0.event.id == eventId })?.event
        }
    }
}

extension HLSInterstitialEventDecisioningActor {
    struct InitialInterstials {
        let preRollInterstitials: [HLSInterstitialEvent]
        let initialInterstitials: [HLSInterstitialInitialEvent]
    }

    enum InitialRequestStatus {
        case notStarted
        case inProgress(Task<Void, Never>)
        case completed(InitialInterstials)

        var inProgressTask: Task<Void, Never>? {
            switch self {
            case .inProgress(let task): return task
            case .completed, .notStarted: return nil
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
