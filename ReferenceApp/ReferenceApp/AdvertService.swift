//
//  AdvertService.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 27/04/2021.
//

import Foundation
import AVFoundation
import HLSInterstitialKit

class AdvertService {
    private let assets = [
        HLSInterstitialEvent.Asset(
            url: URL(string: "https://akam.daps.nbcuni.com/m/1/169843/19/11616659/015K831ANW12021H_ENT_MEZZ_HULU_3318934_730/master_cmaf.m3u8")!,
            duration: 15
        ),
        HLSInterstitialEvent.Asset(
            url: URL(string: "https://akam.daps.nbcuni.com/m/1/169843/71/11616583/015K601GON12021H_ENT_MEZZ_HULU_3318920_730/master_cmaf.m3u8")!,
            duration: 15
        )
    ]
    private let preRollAssets = [
        HLSInterstitialEvent.Asset(
            url: URL(string: "https://akam.daps.nbcuni.com/m/1/169843/104/11614952/030G831NBC11021H_ENT_MEZZ_HULU_3318615_730/master_cmaf.m3u8")!,
            duration: 30
        ),
        HLSInterstitialEvent.Asset(
            url: URL(string: "https://akam.daps.nbcuni.com/m/1/169843/19/11616659/015K831ANW12021H_ENT_MEZZ_HULU_3318934_730/master_cmaf.m3u8")!,
            duration: 15
        ),
        HLSInterstitialEvent.Asset(
            url: URL(string: "https://akam.daps.nbcuni.com/m/1/169843/71/11616583/015K601GON12021H_ENT_MEZZ_HULU_3318920_730/master_cmaf.m3u8")!,
            duration: 15
        )
    ]

    func getInterstitialPreRoll() -> HLSInterstitialEvent {
        HLSInterstitialEvent(
            assets: preRollAssets,
            restrictions: [.restrictJump, .restrictSkip],
            cue: .joinCue
        )
    }
    
    func getInterstitialEvent(forDuration duration: TimeInterval, resumeOffset: TimeInterval? = nil) -> HLSInterstitialEvent {
        HLSInterstitialEvent(
            assets: getAdAssets(forDuration: duration),
            resumeOffset: resumeOffset,
            restrictions: [.restrictJump, .restrictSkip]
        )
    }

    func getAVInterstitialEvent(
        primaryItem: AVPlayerItem,
        forTime time: TimeInterval,
        forDuration duration: TimeInterval,
        resumeOffset: TimeInterval? = nil
    ) -> AVPlayerInterstitialEvent {
        AVPlayerInterstitialEvent(
            primaryItem: primaryItem,
            identifier: "\(time) (\(duration))",
            time: CMTime(seconds: time, preferredTimescale: 1),
            templateItems: getAdAssets(forDuration: duration).map { AVPlayerItem(url: $0.url) },
            restrictions: [.constrainsSeekingForwardInPrimaryContent, .requiresPlaybackAtPreferredRateForAdvancement],
            resumptionOffset: resumeOffset.map { CMTime(seconds: $0, preferredTimescale: 1) } ?? .indefinite
        )
    }

    func getAVInterstitialEvent(
        primaryItem: AVPlayerItem,
        forDate date: Date,
        forDuration duration: TimeInterval,
        resumeOffset: TimeInterval? = nil
    ) -> AVPlayerInterstitialEvent {
        AVPlayerInterstitialEvent(
            primaryItem: primaryItem,
            identifier: "\(date) (\(duration))",
            date: date,
            templateItems: getAdAssets(forDuration: duration).map { AVPlayerItem(url: $0.url) },
            restrictions: [.constrainsSeekingForwardInPrimaryContent, .requiresPlaybackAtPreferredRateForAdvancement],
            resumptionOffset: resumeOffset.map { CMTime(seconds: $0, preferredTimescale: 1) } ?? .indefinite
        )
    }

    func getAVInterstitialPreRoll(primaryItem: AVPlayerItem) -> AVPlayerInterstitialEvent {
        let event = AVPlayerInterstitialEvent(
            primaryItem: primaryItem,
            identifier: "Interstitial PreRoll Event",
            time: .zero,
            templateItems: preRollAssets.map { AVPlayerItem(url: $0.url) }
        )
        if #available(iOS 16, tvOS 16, *) {
            event.cue = .joinCue
        }
        return event
    }
    
    private func getAdAssets(forDuration duration: TimeInterval) -> [HLSInterstitialEvent.Asset] {
        var durationLeft = duration + 1 // Give a little space for over-filling by a small amount.
        var adAssets = [HLSInterstitialEvent.Asset]()
        var count = -1
        while durationLeft > 0 {
            count += 1
            let asset = assets[count % 2]
            durationLeft -= asset.duration
            if durationLeft < 0 {
                break
            }
            adAssets.append(asset)
        }
        return adAssets
    }
}
