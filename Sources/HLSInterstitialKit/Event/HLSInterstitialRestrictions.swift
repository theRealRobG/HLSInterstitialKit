public struct HLSInterstitialRestrictions: OptionSet {
    /// Indicates that while the interstitial is being played, the client should not allow the user to jump forward from the current
    /// playhead position or set the rate to greater than the regular playback rate until playback reaches the end of the interstitial.
    public static let restrictSkip = HLSInterstitialRestrictions(rawValue: 1 << 0)
    /// Indicates that the client should not allow the user to seek from a position in the primary asset earlier than the start of the
    /// interstitial to a position after it without first playing the interstitial asset, even if the interstitial was played through earlier. If the
    /// user attempts to jump across more than one interstitial, the client should choose at least one interstitial to play before allowing
    /// the jump to complete.
    public static let restrictJump = HLSInterstitialRestrictions(rawValue: 1 << 1)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
