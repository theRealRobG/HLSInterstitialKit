import mamba

class MediaPlaylistManipulator {
    weak var decisionHandler: HLSInterstitialEventLoadingRequestDecisionHandler? {
        get { eventDecisioner.decisionHandler }
        set { eventDecisioner.decisionHandler = newValue }
    }

    private let eventDecisioner = HLSInterstitialEventDecisioner()
    private let defaultVODStartDate = Date(timeIntervalSince1970: 0)
    
    func manipulate(playlist: inout HLSPlaylist) async throws -> Data {
        playlist.convertURLsFromInterstitialScheme()

        let requestParameters = getNewRequestParameters(forPlaylist: playlist)
        let eventsResponse = await eventDecisioner.events(forParameters: requestParameters, playlist: playlist)

        addInterstitialsForVOD(playlist: &playlist, interstitials: eventsResponse.initialInterstitials)
        addInterstitialsForPreRoll(playlist: &playlist, interstitials: eventsResponse.preRollInterstitials)
        addInterstitialsForLive(playlist: &playlist, events: eventsResponse.idToEventMap)

        return try playlist.write()
    }

    func assetList(forId id: String) async -> AssetListResponse {
        let event = await eventDecisioner.event(forId: id)
        return event.map { AssetListResponse(assets: $0.assets) } ?? AssetListResponse(assets: [])
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

    private func addInterstitialsForPreRoll(playlist: inout HLSPlaylist, interstitials: [HLSInterstitialEvent]) {
        let events = interstitials.filter { $0.cue.contains(.joinCue) }
        let tags = events.flatMap { $0.dateRangeTags(forDate: Date(timeIntervalSince1970: 0)) }
        guard let insertionIndex = playlist.mediaSegmentGroups.first?.startIndex else { return }
        playlist.insert(tags: tags, atIndex: insertionIndex)
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
    
    private func getNewRequestParameters(
        forPlaylist playlist: HLSPlaylist
    ) -> [String: HLSInterstitialEventLoadingRequest.Parameters] {
        playlist.tags
            .filter { $0.tagDescriptor == PantosTag.EXT_X_DATERANGE }
            .compactMap { $0.eventLoadingRequestParameters }
            .combinedRequestParameters()
            .reduce(into: [String: HLSInterstitialEventLoadingRequest.Parameters]()) { $0[$1.id] = $1 }
    }
}
