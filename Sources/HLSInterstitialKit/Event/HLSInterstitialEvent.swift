import Foundation

public struct HLSInterstitialEvent {
    /// Each value in the array is an absolute URL for a single interstitial asset.
    public let urls: [URL]
    /// Specifies where primary playback should resume following the playback of the interstitial. It is expressed as a time offset from
    /// where the interstitial playback was scheduled on the primary player timeline. A typical value is `.zero`. If the
    /// `resumeOffset` is not present, the player uses the duration of interstitial playback for the resume offset, which is
    /// appropriate for live playback where playback is to be kept at a constant delay from the live edge, or for VOD playback where
    /// the HLS interstitial is intended to replace content in the primary asset.
    public let resumeOffset: TimeInterval?
    /// Specifies a limit for the playout time of the entire interstitial. If it is present, the player should end the interstitial if playback
    /// reaches that offset from its start. Otherwise the interstitial should end upon reaching the end of the interstitial asset(s).
    public let playoutDurationLimit: TimeInterval?
    /// Specifies the restrictions that should apply to this interstitial (see
    /// [HLSInterstitialRestrictions](x-source-tag://HLSInterstitialRestrictions)) for available restrictions.
    public let restrictions: HLSInterstitialRestrictions
    
    public init(
        urls: [URL],
        resumeOffset: TimeInterval? = nil,
        playoutDurationLimit: TimeInterval? = nil,
        restrictions: HLSInterstitialRestrictions = []
    ) {
        self.urls = urls
        self.resumeOffset = resumeOffset
        self.playoutDurationLimit = playoutDurationLimit
        self.restrictions = restrictions
    }
}
