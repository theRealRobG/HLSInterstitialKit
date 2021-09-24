//
//  AVPlayerInterstitialEvent+Extension.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 24/09/2021.
//

import AVFoundation

@available(iOS 15, tvOS 15, *)
extension AVPlayerInterstitialEvent {
    func updated(resumptionOffset: CMTime) -> AVPlayerInterstitialEvent {
        guard let primaryItem = self.primaryItem else {
            assertionFailure("Cannot update the event if the primary item is dereferenced")
            return self
        }
        if let date = self.date {
            return AVPlayerInterstitialEvent(
                primaryItem: primaryItem,
                identifier: identifier,
                date: date,
                templateItems: templateItems,
                restrictions: restrictions,
                resumptionOffset: resumptionOffset,
                playoutLimit: playoutLimit,
                userDefinedAttributes: userDefinedAttributes as? [String: Any] ?? [:]
            )
        } else {
            return AVPlayerInterstitialEvent(
                primaryItem: primaryItem,
                identifier: identifier,
                time: time,
                templateItems: templateItems,
                restrictions: restrictions,
                resumptionOffset: resumptionOffset,
                playoutLimit: playoutLimit,
                userDefinedAttributes: userDefinedAttributes as? [String: Any] ?? [:]
            )
        }
    }
}
