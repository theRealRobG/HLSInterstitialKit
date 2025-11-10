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
    private let assets = [HLSInterstitialEvent.Asset]()
    private let preRollAssets = [HLSInterstitialEvent.Asset]()

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
//        [HLSInterstitialEvent.Asset(
//            url: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8")!,
//            duration: 98)
//        ]
        []
//        var durationLeft = duration + 1 // Give a little space for over-filling by a small amount.
//        var adAssets = [HLSInterstitialEvent.Asset]()
//        var count = -1
//        while durationLeft > 0 {
//            count += 1
//            let asset = assets[count % 2]
//            durationLeft -= asset.duration
//            if durationLeft < 0 {
//                break
//            }
//            adAssets.append(asset)
//        }
//        return adAssets
    }
}
