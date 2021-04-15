import Foundation
import mamba

struct StringConvertibleHLSValueData: CustomStringConvertible {
    let value: String
    let quoteEscaped: Bool
    let hlsValueData: HLSValueData
    
    var description: String {
        if quoteEscaped {
            return "\"\(value)\""
        } else {
            return value
        }
    }
    
    init(value: String, quoteEscaped: Bool) {
        self.value = value
        self.quoteEscaped = quoteEscaped
        self.hlsValueData = HLSValueData(value: value, quoteEscaped: quoteEscaped)
    }
}

extension OrderedDictionary where K == String, V == StringConvertibleHLSValueData {
    var hlsTagDictionary: HLSTagDictionary {
        reduce(into: HLSTagDictionary()) { $0[$1.0] = $1.1.hlsValueData }
    }
}
