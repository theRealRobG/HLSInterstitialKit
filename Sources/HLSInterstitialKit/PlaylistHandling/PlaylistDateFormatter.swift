import Foundation
import mamba

struct PlaylistDateFormatter {
    static func string(from date: Date) -> String {
        if #available(iOS 11, tvOS 11, macOS 10.12, macCatalyst 13, *) {
            return ISO8601DateFormatterWrapper.formatter.string(from: date)
        } else {
            return CustomISO8601DateFormatter.formatter.string(from: date)
        }
    }
    
    static func programDateTime(from date: Date) -> HLSTag {
        let dateString = string(from: date)
        return HLSTag(
            tagDescriptor: PantosTag.EXT_X_PROGRAM_DATE_TIME,
            stringTagData: dateString,
            parsedValues: [PantosValue.programDateTime.toString(): HLSValueData(value: dateString, quoteEscaped: false)]
        )
    }
}

@available(iOS 11, tvOS 11, macOS 10.12, macCatalyst 13, *)
private struct ISO8601DateFormatterWrapper {
    static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        formatter.formatOptions.insert(.withInternetDateTime)
        return formatter
    }()
}

private struct CustomISO8601DateFormatter {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()
}
