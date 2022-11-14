import Foundation
import mamba
import SCTE35Parser

public typealias HLSInterstitialEventLoadingRequestResult = Result<
    [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent?],
    Error
>

protocol HLSInterstitialEventLoadingRequestDelegate: AnyObject {
    func interstitialEventLoadingRequest(
        _ request: HLSInterstitialEventLoadingRequest,
        didFinishLoadingWithResult result: HLSInterstitialEventLoadingRequestResult,
        preRollInterstitials: [HLSInterstitialEvent],
        midRollInterstiitals: [HLSInterstitialInitialEvent]
    )
    
    func interstitialEventLoadingRequestDidGetCancelled(
        _ request: HLSInterstitialEventLoadingRequest
    )
}

public class HLSInterstitialEventLoadingRequest: Hashable {
    public static func == (lhs: HLSInterstitialEventLoadingRequest, rhs: HLSInterstitialEventLoadingRequest) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public let parameters: [Parameters]
    public let playlist: HLSPlaylist
    
    public fileprivate(set) var isFinished = false
    public private(set) var isCancelled = false
    
    weak var delegate: HLSInterstitialEventLoadingRequestDelegate?
    
    public init(parameters: [Parameters], playlist: HLSPlaylist) {
        self.parameters = parameters
        self.playlist = playlist
    }
    
    convenience init(
        parameters: [Parameters],
        playlist: HLSPlaylist,
        delegate: HLSInterstitialEventLoadingRequestDelegate
    ) {
        self.init(parameters: parameters, playlist: playlist)
        self.delegate = delegate
    }
    
    public func finishLoading(withResult result: HLSInterstitialEventLoadingRequestResult) {
        if isCancelled || isFinished { return }
        isFinished = true
        delegate?.interstitialEventLoadingRequest(
            self,
            didFinishLoadingWithResult: result,
            preRollInterstitials: [],
            midRollInterstiitals: []
        )
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    func cancel() {
        if isCancelled || isFinished { return }
        isCancelled = true
        delegate?.interstitialEventLoadingRequestDidGetCancelled(self)
    }
}

public class HLSInterstitialEventInitialLoadingRequest: HLSInterstitialEventLoadingRequest {
    public func finishLoading(
        withResult result: HLSInterstitialEventLoadingRequestResult,
        preRollInterstitials: [HLSInterstitialEvent],
        midRollInterstitials: [HLSInterstitialInitialEvent]
    ) {
        if isCancelled || isFinished { return }
        isFinished = true
        delegate?.interstitialEventLoadingRequest(
            self,
            didFinishLoadingWithResult: result,
            preRollInterstitials: preRollInterstitials,
            midRollInterstiitals: midRollInterstitials
        )
    }
}

public extension HLSInterstitialEventLoadingRequest {
    struct Parameters: Hashable {
        public let id: String
        public let startDate: Date
        public let classAttribute: String?
        public let endDate: Date?
        public let duration: TimeInterval?
        public let plannedDuration: TimeInterval?
        public let endOnNext: Bool
        public let scte35CMD: SpliceInfoSection?
        public let scte35Out: SpliceInfoSection?
        public let scte35In: SpliceInfoSection?
        public let customAtributes: [String: ValidCustomAttribute]
        
        public init(
            id: String,
            startDate: Date,
            classAttribute: String? = nil,
            endDate: Date? = nil,
            duration: TimeInterval? = nil,
            plannedDuration: TimeInterval? = nil,
            endOnNext: Bool = false,
            scte35CMD: SpliceInfoSection? = nil,
            scte35Out: SpliceInfoSection? = nil,
            scte35In: SpliceInfoSection? = nil,
            customAtributes: [String: ValidCustomAttribute] = [:]
        ) {
            self.id = id
            self.startDate = startDate
            self.classAttribute = classAttribute
            self.endDate = endDate
            self.duration = duration
            self.plannedDuration = plannedDuration
            self.endOnNext = endOnNext
            self.scte35CMD = scte35CMD
            self.scte35Out = scte35Out
            self.scte35In = scte35In
            self.customAtributes = customAtributes
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

public extension HLSInterstitialEventLoadingRequest.Parameters {
    enum ValidCustomAttribute: Equatable {
        case string(String)
        case number(Double)
    }
}

public extension HLSInterstitialEventLoadingRequest.Parameters {
    func combined(with other: HLSInterstitialEventLoadingRequest.Parameters) -> HLSInterstitialEventLoadingRequest.Parameters? {
        guard id == other.id else { return nil }
        return HLSInterstitialEventLoadingRequest.Parameters(
            id: id,
            startDate: startDate,
            classAttribute: classAttribute ?? other.classAttribute,
            endDate: endDate ?? other.endDate,
            duration: duration ?? other.duration,
            plannedDuration: plannedDuration ?? other.plannedDuration,
            endOnNext: endOnNext || other.endOnNext,
            scte35CMD: scte35CMD ?? other.scte35CMD,
            scte35Out: scte35Out ?? other.scte35Out,
            scte35In: scte35In ?? other.scte35In,
            customAtributes: other.customAtributes.merging(customAtributes, uniquingKeysWith: { $1 })
        )
    }
}

public extension Array where Element == HLSInterstitialEventLoadingRequest.Parameters {
    func combinedRequestParameters() -> [Element] {
        var combinedParameters = [Element]()
        for params in self {
            let combinedParams = reduce(params) { $0.combined(with: $1) ?? $0 }
            combinedParameters.append(combinedParams)
        }
        return combinedParameters.reduce(into: [Element]()) { parameters, params in
            guard !parameters.contains(params) else { return }
            parameters.append(params)
        }
    }
}
