import Foundation

public struct HLSInterstitialInitialEvent {
    public let event: HLSInterstitialEvent
    public let startTime: TimeInterval
    
    public init(event: HLSInterstitialEvent, startTime: TimeInterval) {
        self.event = event
        self.startTime = startTime
    }
}
