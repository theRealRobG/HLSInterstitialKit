import Foundation

public struct HLSInterstitialEvent {
    public let urls: [URL]
    public let resumeOffset: TimeInterval
    public let playoutDurationLimit: TimeInterval?
    public let restrictions: HLSInterstitialRestrictions
    
    public init(
        urls: [URL],
        resumeOffset: TimeInterval,
        playoutDurationLimit: TimeInterval? = nil,
        restrictions: HLSInterstitialRestrictions = []
    ) {
        self.urls = urls
        self.resumeOffset = resumeOffset
        self.playoutDurationLimit = playoutDurationLimit
        self.restrictions = restrictions
    }
}
