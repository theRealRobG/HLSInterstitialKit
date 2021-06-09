/// - Tag: HLSInterstitialSnap
public struct HLSInterstitialSnap: OptionSet {
    /// Indicates that the client _should_ locate the segment boundary closest to the `START-DATE` of the interstitial in the Media
    /// Playlist of the primary content and transition to the interstitial at that boundary. If more than one Media Playlist is contributing
    /// to playback (audio plus video for example), the player _should_ transition at the earliest segment boundary.
    public static let snapOut = HLSInterstitialSnap(rawValue: 1 << 0)
    /// Indicates that the client _should_ locate the segment boundary closest to the scheduled resumption point from the interstitial
    /// in the Media Playlist of the primary content and resume playback of primary content at that boundary. If more than one Media
    /// Playlist is contributing to playback, the player _should_ transition at the latest segment boundary.
    public static let snapIn = HLSInterstitialSnap(rawValue: 1 << 1)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
