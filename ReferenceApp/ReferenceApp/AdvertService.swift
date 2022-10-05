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
    private let adDuration = 15.0
    private let urls = [
        URL(string: "https://mssl.fwmrm.net/m/1/169843/59/6662075/YVWF0614000H_ENT_MEZZ_HULU_1925786_646/master_cmaf.m3u8")!,
        URL(string: "https://mssl.fwmrm.net/m/1/169843/17/6662161/SBON9969000H_ENT_MEZZ_HULU_1925782_646/master_cmaf.m3u8")!
    ]
    private let preRollURLs = [
        URL(string: "https://akam.daps.nbcuni.com/m/1/169843/104/11614952/030G831NBC11021H_ENT_MEZZ_HULU_3318615_730/master_cmaf.m3u8")!,
        URL(string: "https://akam.daps.nbcuni.com/m/1/169843/19/11616659/015K831ANW12021H_ENT_MEZZ_HULU_3318934_730/master_cmaf.m3u8")!,
        URL(string: "https://akam.daps.nbcuni.com/m/1/169843/71/11616583/015K601GON12021H_ENT_MEZZ_HULU_3318920_730/master_cmaf.m3u8")!
    ]

    func getInterstitialPreRoll() -> HLSInterstitialEvent {
        HLSInterstitialEvent(
            urls: preRollURLs,
            restrictions: [.restrictJump, .restrictSkip],
            cue: .joinCue
        )
    }
    
    func getInterstitialEvent(forDuration duration: TimeInterval, resumeOffset: TimeInterval? = nil) -> HLSInterstitialEvent {
        HLSInterstitialEvent(
            urls: getAdURLs(forDuration: duration),
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
            templateItems: getAdURLs(forDuration: duration).map { AVPlayerItem(url: $0) },
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
            templateItems: getAdURLs(forDuration: duration).map { AVPlayerItem(url: $0) },
            restrictions: [.constrainsSeekingForwardInPrimaryContent, .requiresPlaybackAtPreferredRateForAdvancement],
            resumptionOffset: resumeOffset.map { CMTime(seconds: $0, preferredTimescale: 1) } ?? .indefinite
        )
    }

    func getAVInterstitialPreRoll(primaryItem: AVPlayerItem) -> AVPlayerInterstitialEvent {
        let event = AVPlayerInterstitialEvent(
            primaryItem: primaryItem,
            identifier: "Interstitial PreRoll Event",
            time: .zero,
            templateItems: preRollURLs.map { AVPlayerItem(url: $0) }
        )
        if #available(iOS 16, tvOS 16, *) {
            event.cue = .joinCue
        }
        return event
    }
    
    private func getAdURLs(forDuration duration: TimeInterval) -> [URL] {
        let durationPlusOne = duration + 1 // Give a little space for over-filling by a small amount.
        let numberOfAds = Int(durationPlusOne / adDuration)
        var adURLs = [URL]()
        for index in 0..<numberOfAds {
            adURLs.append(urls[index % 2])
        }
        return adURLs
    }
}
