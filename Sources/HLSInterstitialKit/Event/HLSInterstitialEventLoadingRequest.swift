import Foundation
import SCTE35Parser

protocol HLSInterstitialEventLoadingRequestDelegate: AnyObject {
    func interstitialEventLoadingRequest(
        _ request: HLSInterstitialEventLoadingRequest,
        didFinishLoadingWithResult result: Result<HLSInterstitialEvent, Error>?
    )
    
    func interstitialEventLoadingRequestDidGetCancelled(
        _ request: HLSInterstitialEventLoadingRequest
    )
}

public class HLSInterstitialEventLoadingRequest {
    public let parameters: Parameters
    
    public private(set) var isFinished = false
    public private(set) var isCancelled = false
    
    weak var delegate: HLSInterstitialEventLoadingRequestDelegate?
    
    public init(parameters: Parameters) {
        self.parameters = parameters
    }
    
    convenience init(parameters: Parameters, delegate: HLSInterstitialEventLoadingRequestDelegate) {
        self.init(parameters: parameters)
        self.delegate = delegate
    }
    
    public func finishLoading(withResult result: Result<HLSInterstitialEvent, Error>?) {
        if isCancelled || isFinished { return }
        isFinished = true
        delegate?.interstitialEventLoadingRequest(self, didFinishLoadingWithResult: result)
    }
    
    func cancel() {
        if isCancelled || isFinished { return }
        isCancelled = true
        delegate?.interstitialEventLoadingRequestDidGetCancelled(self)
    }
}

public extension HLSInterstitialEventLoadingRequest {
    struct Parameters: Equatable {
        public let id: String
        public let startDate: Date
        public let dateRangeClass: String?
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
            dateRangeClass: String? = nil,
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
            self.dateRangeClass = dateRangeClass
            self.endDate = endDate
            self.duration = duration
            self.plannedDuration = plannedDuration
            self.endOnNext = endOnNext
            self.scte35CMD = scte35CMD
            self.scte35Out = scte35Out
            self.scte35In = scte35In
            self.customAtributes = customAtributes
        }
    }
}

public extension HLSInterstitialEventLoadingRequest.Parameters {
    enum ValidCustomAttribute: Equatable {
        case string(String)
        case number(Double)
    }
}
