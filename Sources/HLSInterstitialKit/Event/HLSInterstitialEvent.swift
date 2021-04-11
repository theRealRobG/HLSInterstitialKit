import AVFoundation

public struct HLSInterstitialEvent {
    public let urls: [URL]
    public let startTime: CMTime
    public let resumeOffset: CMTime
    public let playoutDurationLimit: CMTime?
    public let restrictions: HLSInterstitialRestrictions
    
    public init(
        urls: [URL],
        startTime: CMTime,
        resumeOffset: CMTime,
        playoutDurationLimit: CMTime? = nil,
        restrictions: HLSInterstitialRestrictions = []
    ) {
        self.urls = urls
        self.startTime = startTime
        self.resumeOffset = resumeOffset
        self.playoutDurationLimit = playoutDurationLimit
        self.restrictions = restrictions
    }
}
