import Foundation
import mamba

extension HLSTag {
    private enum URLConversionDirection {
        case fromInterstitialURL
        case toInterstitialURL
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
