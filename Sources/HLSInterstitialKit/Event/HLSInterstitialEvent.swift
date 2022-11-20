import Foundation
import mamba

public struct HLSInterstitialEvent {
    /// Uniquely identifies a Date Range in the Playlist.
    public let id: String
    /// Each value in the array is an absolute URL and duration for a single interstitial asset.
    public let assets: [Asset]
    /// Specifies where primary playback should resume following the playback of the interstitial.
    ///
    /// It is expressed as a time offset from where the interstitial playback was scheduled on the primary player
    /// timeline. A typical value is `.zero`. If the `resumeOffset` is not present, the player uses the duration of
    /// interstitial playback for the resume offset, which is appropriate for live playback where playback is to be kept
    /// at a constant delay from the live edge, or for VOD playback where the HLS interstitial is intended to replace
    /// content in the primary asset.
    public let resumeOffset: TimeInterval?
    /// Indicates rules on where the interstitial should snap to within the primary content.
    ///
    /// See [HLSInterstitialSnap](x-source-tag://HLSInterstitialSnap) for available options.
    public let snap: HLSInterstitialSnap
    /// Specifies a limit for the playout time of the entire interstitial.
    ///
    /// If it is present, the player should end the interstitial if playback reaches that offset from its start.
    /// Otherwise the interstitial should end upon reaching the end of the interstitial asset(s).
    public let playoutDurationLimit: TimeInterval?
    /// Specifies the restrictions that should apply to this interstitial.
    ///
    /// See [HLSInterstitialRestrictions](x-source-tag://HLSInterstitialRestrictions) for available restrictions.
    public let restrictions: HLSInterstitialRestrictions
    /// A cue to schedule interstitial event playback at a predefined position during primary playback.
    public let cue: Cue
    
    public init(
        assets: [Asset],
        resumeOffset: TimeInterval? = nil,
        snap: HLSInterstitialSnap = [],
        playoutDurationLimit: TimeInterval? = nil,
        restrictions: HLSInterstitialRestrictions = [],
        cue: Cue = .noCue
    ) {
        self.id = UUID().uuidString
        self.assets = assets
        self.resumeOffset = resumeOffset
        self.snap = snap
        self.playoutDurationLimit = playoutDurationLimit
        self.restrictions = restrictions
        self.cue = cue
    }
    
    init(
        id: String,
        assets: [Asset],
        resumeOffset: TimeInterval? = nil,
        snap: HLSInterstitialSnap = [],
        playoutDurationLimit: TimeInterval? = nil,
        restrictions: HLSInterstitialRestrictions = [],
        cue: Cue = .noCue
    ) {
        self.id = id
        self.assets = assets
        self.resumeOffset = resumeOffset
        self.snap = snap
        self.playoutDurationLimit = playoutDurationLimit
        self.restrictions = restrictions
        self.cue = cue
    }
}

extension HLSInterstitialEvent {
    func dateRangeTags(forDate date: Date) -> [HLSTag] {
        if #available(iOS 16.1, tvOS 16.1, *) {
            var parsedValues = commonParsedValues(forDate: date)
            parsedValues["ID"] = StringConvertibleHLSValueData(value: id, quoteEscaped: true)
            parsedValues["X-ASSET-LIST"] = StringConvertibleHLSValueData(
                value: URL.assetListBaseURL
                    .appending(queryItems: [URLQueryItem(name: "_HLS_interstitial_id", value: id)])
                    .absoluteString,
                quoteEscaped: true
            )
            return [tag(fromParsedValues: parsedValues)]
        } else {
            return assets.map { $0.url }.enumerated().reduce(into: [HLSTag]()) { tags, enumerated in
                let url = enumerated.element
                let index = enumerated.offset
                var parsedValues = commonParsedValues(forDate: date)
                parsedValues["ID"] = StringConvertibleHLSValueData(value: "\(id)_\(index)", quoteEscaped: true)
                parsedValues["X-ASSET-URI"] = StringConvertibleHLSValueData(
                    value: url.absoluteString,
                    quoteEscaped: true
                )
                let tag = tag(fromParsedValues: parsedValues)
                tags.append(tag)
            }
        }
    }

    private func commonParsedValues(forDate date: Date) -> OrderedDictionary<String, StringConvertibleHLSValueData> {
        var parsedValues: OrderedDictionary<String, StringConvertibleHLSValueData> = [
            "START-DATE": StringConvertibleHLSValueData(
                value: PlaylistDateFormatter.string(from: date),
                quoteEscaped: true
            ),
            "CLASS": StringConvertibleHLSValueData(value: "com.apple.hls.interstitial", quoteEscaped: true)
        ]
        if let resumeOffset = resumeOffset {
            parsedValues["X-RESUME-OFFSET"] = StringConvertibleHLSValueData(
                value: String(resumeOffset),
                quoteEscaped: false
            )
        }
        if let playoutDurationLimit = playoutDurationLimit {
            parsedValues["X-PLAYOUT-LIMIT"] = StringConvertibleHLSValueData(
                value: String(playoutDurationLimit),
                quoteEscaped: false
            )
        }
        if !snap.isEmpty {
            var stringList = [String]()
            if snap.contains(.snapIn) {
                stringList.append("IN")
            }
            if snap.contains(.snapOut) {
                stringList.append("OUT")
            }
            parsedValues["X-SNAP"] = StringConvertibleHLSValueData(
                value: stringList.joined(separator: ","),
                quoteEscaped: true
            )
        }
        if !restrictions.isEmpty {
            var stringList = [String]()
            if restrictions.contains(.restrictJump) {
                stringList.append("JUMP")
            }
            if restrictions.contains(.restrictSkip) {
                stringList.append("SKIP")
            }
            parsedValues["X-RESTRICT"] = StringConvertibleHLSValueData(
                value: stringList.joined(separator: ","),
                quoteEscaped: true
            )
        }
        if !cue.isEmpty {
            var stringList = [String]()
            if !cue.contains(.noCue) {
                if cue.contains(.joinCue) {
                    stringList.append("PRE")
                }
                if cue.contains(.leaveCue) {
                    stringList.append("POST")
                }
            }
            if !stringList.isEmpty {
                parsedValues["CUE"] = StringConvertibleHLSValueData(
                    value: stringList.joined(separator: ","),
                    quoteEscaped: true
                )
            }
        }
        return parsedValues
    }

    private func tag(
        fromParsedValues parsedValues: OrderedDictionary<String, StringConvertibleHLSValueData>
    ) -> HLSTag {
        HLSTag(
            tagDescriptor: PantosTag.EXT_X_DATERANGE,
            tagData: HLSStringRef(string: parsedValues.reduce("") { "\($0)\($0.isEmpty ? "" : ",")\($1.0)=\($1.1)" }),
            tagName: HLSStringRef(descriptor: PantosTag.EXT_X_DATERANGE),
            parsedValues: parsedValues.hlsTagDictionary
        )
    }
}

public extension HLSInterstitialEvent {
    struct Asset: Encodable {
        public let url: URL
        public let duration: TimeInterval

        public init(url: URL, duration: TimeInterval) {
            self.url = url
            self.duration = duration
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(url, forKey: .url)
            try container.encode(duration, forKey: .duration)
        }

        enum CodingKeys: String, CodingKey {
            case url = "URI"
            case duration = "DURATION"
        }
    }

    /// A structure that defines standard cues to play interstitial content.
    struct Cue: OptionSet {
        /// A cue that indicates that playback starts at the interstitial event time or date.
        public static let noCue = Self(rawValue: 1 << 0)
        /// A cue that indicates that playback occurs before starting primary playback, regardless of initial primary
        /// playback position.
        public static let joinCue = Self(rawValue: 1 << 1)
        /// A cue that indicates event playback occurs after primary playback ends without error, either at the end of
        /// the primary asset or at the client-specified forward playback end time.
        public static let leaveCue = Self(rawValue: 1 << 2)

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}
