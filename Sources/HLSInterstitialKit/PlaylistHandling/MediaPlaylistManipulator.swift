import mamba

class MediaPlaylistManipulator {
    private let defaultVODStartDate = Date(timeIntervalSince1970: 0)
    
    func manipulate(
        playlist: inout HLSPlaylist,
        initialInterstitials: [HLSInterstitialInitialEvent],
        completion: @escaping (Result<Data, HLSInterstitialError>) -> Void
    ) {
        do {
            playlist.convertURLsFromInterstitialScheme()
            addInterstitialsForVOD(playlist: &playlist, interstitials: initialInterstitials)
            let playlistData = try playlist.write()
            completion(.success(playlistData))
        } catch {
            guard let interstitialError = error as? HLSInterstitialError else {
                return completion(.failure(.playlistParseError(PlaylistParseError(error))))
            }
            completion(.failure(interstitialError))
        }
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
}
