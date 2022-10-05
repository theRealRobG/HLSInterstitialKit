import mamba

class MediaPlaylistManipulator {
    weak var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler?
    
    private let defaultVODStartDate = Date(timeIntervalSince1970: 0)
    private var requestedIDs = [String]()
    private var activeRequest: RequestedEventCompletionInfo?
    private var idToEventMap = [String: HLSInterstitialEvent]()
    
    func manipulate(
        playlist: inout HLSPlaylist,
        initialInterstitials: [HLSInterstitialInitialEvent],
        preRollInterstitials: [HLSInterstitialEvent],
        completion: @escaping (Result<Data, HLSInterstitialError>) -> Void
    ) {
        playlist.convertURLsFromInterstitialScheme()
        addInterstitialsForVOD(playlist: &playlist, interstitials: initialInterstitials)
        addInterstitialsForPreRollLive(playlist: &playlist, interstitials: preRollInterstitials)
        addInterstitialsForLive(playlist: &playlist, completion: completion)
    }
    
    private func addInterstitialsForVOD(playlist: inout HLSPlaylist, interstitials: [HLSInterstitialInitialEvent]) {
        // Only insert initial interstitial for VOD playlist type
        guard
            let playlistTypeTag = playlist.tags.first(.EXT_X_PLAYLIST_TYPE),
            let playlistType = playlistTypeTag.value(.playlistType) as HLSPlaylistType?,
            playlistType.type == .VOD
        else {
            return
        }
        // For now do not consider VOD that already includes a PDT
        // (worry about mis-matching date ranges between video/audio etc.)
        if playlist.tags.contains(.EXT_X_PROGRAM_DATE_TIME) {
            return
        }
        // Add in the PDT and then the date-ranges for the interstitials
        let pdt = PlaylistDateFormatter.programDateTime(from: defaultVODStartDate)
        let dateRangeTags = interstitials.reduce(into: [HLSTag]()) { tags, interstitial in
            let startDate = defaultVODStartDate.addingTimeInterval(interstitial.startTime)
            let eventTags = interstitial.event.dateRangeTags(forDate: startDate)
            tags.append(contentsOf: eventTags)
        }
        playlist.insert(
            tags: [pdt] + dateRangeTags,
            atIndex: playlist.header?.endIndex ?? 0
        )
    }

    private func addInterstitialsForPreRollLive(playlist: inout HLSPlaylist, interstitials: [HLSInterstitialEvent]) {
        let events = interstitials.filter { $0.cue.contains(.joinCue) }
        let tags = events.flatMap { $0.dateRangeTags(forDate: Date(timeIntervalSince1970: 0)) }
        guard let insertionIndex = playlist.mediaSegmentGroups.first?.startIndex else { return }
        playlist.insert(tags: tags, atIndex: insertionIndex)
    }
    
    private func addInterstitialsForLive(playlist: inout HLSPlaylist, completion: @escaping (Result<Data, HLSInterstitialError>) -> Void) {
        let requestParameters = getNewRequestParameters(forPlaylist: playlist)
        guard let decisionHandler = decisionHandler, !requestParameters.isEmpty else {
            if let activeRequest = activeRequest {
                activeRequest.dependents.append(RequestedEventCompletionDependent(playlist: playlist, completion: completion))
            } else {
                completeInsertion(playlist: &playlist, completion: completion)
            }
            return
        }
        if let activeRequest = activeRequest {
            // If we're still waiting for a previous decision and another one rolls in just drop the previous request.
            // This is a simplification for now and I suppose should be improved in the future.
            activeRequest.loadingRequest.cancel()
        }
        let eventRequest = HLSInterstitialEventLoadingRequest(parameters: requestParameters, playlist: playlist, delegate: self)
        activeRequest = RequestedEventCompletionInfo(loadingRequest: eventRequest, completion: completion)
        guard decisionHandler.shouldWaitForLoadingOfRequest(eventRequest) else {
            activeRequest = nil
            completeInsertion(playlist: &playlist, completion: completion)
            return
        }
    }
    
    private func addInterstitialsForLive(playlist: inout HLSPlaylist, events: [String: HLSInterstitialEvent]) {
        let indicesToTagMap = events.reduce(into: [Int: [HLSTag]]()) { indexMap, eventMap in
            let (id, event) = eventMap
            guard let parentTagIndex = playlist.tags.firstIndex(where: { $0.tagDescriptor == PantosTag.EXT_X_DATERANGE && $0.value(.id) == id }) else { return }
            guard let parentTagDate = playlist.tags[parentTagIndex].value(.startDate).map({ Date(string: $0) }) ?? nil else { return }
            let tags = event.dateRangeTags(forDate: parentTagDate)
            indexMap[parentTagIndex] = tags
        }
        for (index, tags) in indicesToTagMap.sorted(by: { $0.key > $1.key }) {
            playlist.insert(tags: tags, atIndex: index)
        }
    }
    
    private func getNewRequestParameters(forPlaylist playlist: HLSPlaylist) -> [HLSInterstitialEventLoadingRequest.Parameters] {
        let parameters = playlist.tags
            .filter { $0.tagDescriptor == PantosTag.EXT_X_DATERANGE && ($0.value(.id).map { id in !requestedIDs.contains(id) } ?? false) }
            .compactMap { $0.eventLoadingRequestParameters }
            .combinedRequestParameters()
        requestedIDs.append(contentsOf: parameters.map { $0.id })
        return parameters
    }
    
    private func completeInsertion(playlist: inout HLSPlaylist, completion: (Result<Data, HLSInterstitialError>) -> Void) {
        do {
            addInterstitialsForLive(playlist: &playlist, events: idToEventMap)
            let playlistData = try playlist.write()
            completion(.success(playlistData))
        } catch {
            guard let interstitialError = error as? HLSInterstitialError else {
                return completion(.failure(.playlistParseError(PlaylistParseError(error))))
            }
            completion(.failure(interstitialError))
        }
    }
}

extension MediaPlaylistManipulator: HLSInterstitialEventLoadingRequestDelegate {
    func interstitialEventLoadingRequest(
        _ request: HLSInterstitialEventLoadingRequest,
        didFinishLoadingWithResult result: Result<[HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent], Error>?
    ) {
        guard let activeRequest = activeRequest, activeRequest.loadingRequest === request else { return }
        switch result {
        case .success(let parameterEventMap):
            for (parameters, event) in parameterEventMap {
                idToEventMap[parameters.id] = event
            }
        case .failure, .none:
            break
        }
        completeInsertion(requestCompletionInfo: activeRequest)
    }
    
    func interstitialEventLoadingRequestDidGetCancelled(
        _ request: HLSInterstitialEventLoadingRequest
    ) {
        guard let activeRequest = activeRequest, activeRequest.loadingRequest === request else { return }
        completeInsertion(requestCompletionInfo: activeRequest)
    }
    
    private func completeInsertion(requestCompletionInfo: RequestedEventCompletionInfo) {
        var playlist = requestCompletionInfo.loadingRequest.playlist
        requestCompletionInfo.loadingRequest.delegate = nil
        activeRequest = nil
        completeInsertion(playlist: &playlist, completion: requestCompletionInfo.completion)
        for dependent in requestCompletionInfo.dependents {
            var dependentPlaylist = dependent.playlist
            completeInsertion(playlist: &dependentPlaylist, completion: dependent.completion)
        }
    }
}

private extension MediaPlaylistManipulator {
    class RequestedEventCompletionInfo {
        let loadingRequest: HLSInterstitialEventLoadingRequest
        let completion: (Result<Data, HLSInterstitialError>) -> Void
        var dependents: [RequestedEventCompletionDependent]
        
        init(
            loadingRequest: HLSInterstitialEventLoadingRequest,
            completion: @escaping (Result<Data, HLSInterstitialError>) -> Void,
            dependents: [RequestedEventCompletionDependent] = []
        ) {
            self.loadingRequest = loadingRequest
            self.completion = completion
            self.dependents = dependents
        }
    }
    
    struct RequestedEventCompletionDependent {
        let playlist: HLSPlaylist
        let completion: (Result<Data, HLSInterstitialError>) -> Void
    }
}
