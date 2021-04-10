import Foundation
import mamba

extension HLSPlaylist {
    private enum URLConversionDirection {
        case fromInterstitialURL
        case toInterstitialURL
    }
    
    mutating func convertURLsToInterstitialScheme() {
        convertURLs(.toInterstitialURL)
    }
    
    mutating func convertURLsFromInterstitialScheme() {
        convertURLs(.fromInterstitialURL)
    }
    
    private mutating func convertURLs(_ direction: URLConversionDirection) {
        let url = self.url
        for (index, tag) in tags.enumerated() {
            let getModifiedTag: (HLSTag) -> HLSTag?
            switch tag.tagDescriptor {
            case PantosTag.EXT_X_MEDIA, PantosTag.EXT_X_I_FRAME_STREAM_INF, PantosTag.EXT_X_MAP:
                switch direction {
                case .fromInterstitialURL: getModifiedTag = { $0.getModifiedTagWithURIAttributeFromInterstitialURL(withPlaylistURL: url) }
                case .toInterstitialURL: getModifiedTag = { $0.getModifiedTagWithURIAttributeToInterstitialURL(withPlaylistURL: url) }
                }
                guard let newTag = getModifiedTag(tag) else { continue }
                delete(atIndex: index)
                insert(tag: newTag, atIndex: index)
            case PantosTag.Location:
                switch direction {
                case .fromInterstitialURL: getModifiedTag = { $0.getModifiedLocationTagFromInterstitialURL(withPlaylistURL: url) }
                case .toInterstitialURL: getModifiedTag = { $0.getModifiedLocationTagToInterstitialURL(withPlaylistURL: url) }
                }
                guard let newLocation = getModifiedTag(tag) else { continue }
                delete(atIndex: index)
                insert(tag: newLocation, atIndex: index)
            default:
                continue
            }
        }
    }
}
