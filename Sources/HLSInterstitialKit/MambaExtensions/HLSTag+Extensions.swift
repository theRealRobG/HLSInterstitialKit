import Foundation
import mamba
import SCTE35Parser

extension Array where Element == HLSTag {
    func first(_ pantosTag: PantosTag) -> HLSTag? {
        first { $0.tagDescriptor == pantosTag }
    }
    
    func firstIndex(_ pantosTag: PantosTag) -> Int? {
        firstIndex(where: { $0.tagDescriptor == pantosTag })
    }
    
    func contains(_ pantosTag: PantosTag) -> Bool {
        contains(where: { $0.tagDescriptor == pantosTag })
    }
}

extension HLSTag {
    private enum URLConversionDirection {
        case fromInterstitialURL
        case toInterstitialURL
    }
    
    var eventLoadingRequestParameters: HLSInterstitialEventLoadingRequest.Parameters? {
        guard tagDescriptor == PantosTag.EXT_X_DATERANGE else { return nil }
        guard let id = value(.id) else { return nil }
        guard let startDateString = value(.startDate), let startDate = Date(string: startDateString) else { return nil }
        let customAttributes = keys.reduce(into: [String: HLSInterstitialEventLoadingRequest.Parameters.ValidCustomAttribute]()) { attributes, key in
            guard key.starts(with: "X-") else { return }
            guard let value = value(forKey: key) else { return }
            if let number = Double(value) {
                attributes[key] = .number(number)
            } else {
                attributes[key] = .string(value)
            }
        }
        return HLSInterstitialEventLoadingRequest.Parameters(
            id: id,
            startDate: startDate,
            classAttribute: value(.classAttribute),
            endDate: value(.endDate).map { Date(string: $0) } ?? nil,
            duration: value(.duration),
            plannedDuration: value(.plannedDuration),
            endOnNext: value(.endOnNext) ?? false,
            scte35CMD: value(.scte35Cmd).map { try? SpliceInfoSection($0) } ?? nil,
            scte35Out: value(.scte35Out).map { try? SpliceInfoSection($0) } ?? nil,
            scte35In: value(.scte35In).map { try? SpliceInfoSection($0) } ?? nil,
            customAtributes: customAttributes
        )
    }
    
    func value(_ pantosValue: PantosValue) -> String? {
        value(forValueIdentifier: pantosValue)
    }
    
    func value<T: FailableStringLiteralConvertible>(_ pantosValue: PantosValue) -> T? {
        value(forValueIdentifier: pantosValue)
    }
    
    /// Returns the TYPE attribute for EXT-X-MEDIA tags
    func getMediaType() -> HLSMediaType.Media? {
        guard let type = value(forValueIdentifier: PantosValue.type) else { return nil }
        return HLSMediaType(mediaType: type)?.type
    }
    
    func getModifiedTagWithURIAttributeToInterstitialURL(withPlaylistURL originalURL: URL) -> HLSTag? {
        return modifyURIAttribute(withPlaylistURL: originalURL, direction: .toInterstitialURL)
    }
    
    func getModifiedTagWithURIAttributeFromInterstitialURL(withPlaylistURL originalURL: URL) -> HLSTag? {
        return modifyURIAttribute(withPlaylistURL: originalURL, direction: .fromInterstitialURL)
    }
    
    func getModifiedLocationTagToInterstitialURL(withPlaylistURL originalURL: URL) -> HLSTag? {
        return modifyLocation(withPlaylistURL: originalURL, direction: .toInterstitialURL)
    }
    
    func getModifiedLocationTagFromInterstitialURL(withPlaylistURL originalURL: URL) -> HLSTag? {
        return modifyLocation(withPlaylistURL: originalURL, direction: .fromInterstitialURL)
    }
    
    private func modifyURIAttribute(withPlaylistURL originalURL: URL, direction: URLConversionDirection) -> HLSTag? {
        guard let uri = self.value(forValueIdentifier: PantosValue.uri) else { return nil }
        guard let modifiedSchemeAbsoluteURL = getModifiedURL(fromURI: uri, withPlaylistURL: originalURL, direction: direction) else {
            return nil
        }
        
        var newTag = self
        newTag.set(value: modifiedSchemeAbsoluteURL.absoluteString, forValueIdentifier: PantosValue.uri)
        return newTag
    }
    
    private func modifyLocation(withPlaylistURL originalURL: URL, direction: URLConversionDirection) -> HLSTag? {
        let uri = self.tagData.stringValue()
        guard let modifiedSchemeAbsoluteURL = getModifiedURL(fromURI: uri, withPlaylistURL: originalURL, direction: direction) else {
            return nil
        }
        
        return HLSTag(
            tagDescriptor: PantosTag.Location,
            tagData: HLSStringRef(string: modifiedSchemeAbsoluteURL.absoluteString)
        )
    }
    
    private func getModifiedURL(
        fromURI uri: String,
        withPlaylistURL originalURL: URL,
        direction: URLConversionDirection
    ) -> URL? {
        guard let absoluteURL = URL(string: uri, relativeTo: originalURL) else { return nil }
        switch direction {
        case .fromInterstitialURL:
            return absoluteURL.fromInterstitialURL()
        case .toInterstitialURL:
            return absoluteURL.toInterstitialURL()
        }
    }
}
