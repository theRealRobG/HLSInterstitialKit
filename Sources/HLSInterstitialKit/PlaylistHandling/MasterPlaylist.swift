import mamba

class MasterPlaylist {
    private let playlist: HLSPlaylist
    private let initialInterstitials: [HLSInterstitialInitialEvent]
    
    init(_ playlist: inout HLSPlaylist, initialInterstitials: [HLSInterstitialInitialEvent]) {
        playlist.convertURLsToInterstitialScheme()
        self.playlist = playlist
        self.initialInterstitials = initialInterstitials
    }
    
    func writeMaster() throws -> Data {
        try playlist.write()
    }
    
    func updateMedia(playlist: inout HLSPlaylist, completion: @escaping (Result<Data, HLSInterstitialError>) -> Void) {
        do {
            playlist.convertURLsFromInterstitialScheme()
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
