import Foundation
import mamba

public struct HLSInterstitialEvent {
    /// Uniquely identifies a Date Range in the Playlist.
    public let id: String
    /// Each value in the array is an absolute URL for a single interstitial asset.
    public let urls: [URL]
    /// Specifies where primary playback should resume following the playback of the interstitial. It is expressed as a time offset from
    /// where the interstitial playback was scheduled on the primary player timeline. A typical value is `.zero`. If the
    /// `resumeOffset` is not present, the player uses the duration of interstitial playback for the resume offset, which is
    /// appropriate for live playback where playback is to be kept at a constant delay from the live edge, or for VOD playback where
    /// the HLS interstitial is intended to replace content in the primary asset.
    public let resumeOffset: TimeInterval?
    /// Indicates rules on where the interstitial should snap to within the primary content (see
    /// [HLSInterstitialSnap](x-source-tag://HLSInterstitialSnap) for available options).
    public let snap: HLSInterstitialSnap
    /// Specifies a limit for the playout time of the entire interstitial. If it is present, the player should end the interstitial if playback
    /// reaches that offset from its start. Otherwise the interstitial should end upon reaching the end of the interstitial asset(s).
    public let playoutDurationLimit: TimeInterval?
    /// Specifies the restrictions that should apply to this interstitial (see
    /// [HLSInterstitialRestrictions](x-source-tag://HLSInterstitialRestrictions) for available restrictions).
    public let restrictions: HLSInterstitialRestrictions
    
    public init(
        urls: [URL],
        resumeOffset: TimeInterval? = nil,
        snap: HLSInterstitialSnap = [],
        playoutDurationLimit: TimeInterval? = nil,
        restrictions: HLSInterstitialRestrictions = []
    ) {
        self.id = UUID().uuidString
        self.urls = urls
        self.resumeOffset = resumeOffset
        self.snap = snap
        self.playoutDurationLimit = playoutDurationLimit
        self.restrictions = restrictions
    }
    
    init(
        id: String,
        urls: [URL],
        resumeOffset: TimeInterval? = nil,
        snap: HLSInterstitialSnap = [],
        playoutDurationLimit: TimeInterval? = nil,
        restrictions: HLSInterstitialRestrictions = []
    ) {
        self.id = id
        self.urls = urls
        self.resumeOffset = resumeOffset
        self.snap = snap
        self.playoutDurationLimit = playoutDurationLimit
        self.restrictions = restrictions
    }
}

extension HLSInterstitialEvent {
    func dateRangeTags(forDate date: Date) -> [HLSTag] {
        urls.enumerated().reduce(into: [HLSTag]()) { tags, enumerated in
            let url = enumerated.element
            let index = enumerated.offset
            var parsedValues: OrderedDictionary<String, StringConvertibleHLSValueData> = [
                "ID": StringConvertibleHLSValueData(value: "\(id)_\(index)", quoteEscaped: true),
                "START-DATE": StringConvertibleHLSValueData(value: PlaylistDateFormatter.string(from: date), quoteEscaped: true),
                "CLASS": StringConvertibleHLSValueData(value: "com.apple.hls.interstitial", quoteEscaped: true),
                "X-ASSET-URI": StringConvertibleHLSValueData(value: url.absoluteString, quoteEscaped: true)
            ]
            if let resumeOffset = resumeOffset {
                parsedValues["X-RESUME-OFFSET"] = StringConvertibleHLSValueData(value: String(resumeOffset), quoteEscaped: false)
            }
            if let playoutDurationLimit = playoutDurationLimit {
                parsedValues["X-PLAYOUT-LIMIT"] = StringConvertibleHLSValueData(value: String(playoutDurationLimit), quoteEscaped: false)
            }
            if !snap.isEmpty {
                var stringList = [String]()
                if snap.contains(.snapIn) {
                    stringList.append("IN")
                }
                if snap.contains(.snapOut) {
                    stringList.append("OUT")
                }
                parsedValues["X-SNAP"] = StringConvertibleHLSValueData(value: stringList.joined(separator: ","), quoteEscaped: true)
            }
            if !restrictions.isEmpty {
                var stringList = [String]()
                if restrictions.contains(.restrictJump) {
                    stringList.append("JUMP")
                }
                if restrictions.contains(.restrictSkip) {
                    stringList.append("SKIP")
                }
                parsedValues["X-RESTRICT"] = StringConvertibleHLSValueData(value: stringList.joined(separator: ","), quoteEscaped: true)
            }
            let tag = HLSTag(
                tagDescriptor: PantosTag.EXT_X_DATERANGE,
                tagData: HLSStringRef(string: parsedValues.reduce("") { "\($0)\($0.isEmpty ? "" : ",")\($1.0)=\($1.1)" }),
                tagName: HLSStringRef(descriptor: PantosTag.EXT_X_DATERANGE),
                parsedValues: parsedValues.hlsTagDictionary
            )
            tags.append(tag)
        }
    }
}
