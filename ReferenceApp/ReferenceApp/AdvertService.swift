//
//  AdvertService.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 27/04/2021.
//

import Foundation
import HLSInterstitialKit

class AdvertService {
    private let adDuration = 15.0
    private let urls = [
        URL(string: "https://mssl.fwmrm.net/m/1/169843/59/6662075/YVWF0614000H_ENT_MEZZ_HULU_1925786_646/master_cmaf.m3u8")!,
        URL(string: "https://mssl.fwmrm.net/m/1/169843/17/6662161/SBON9969000H_ENT_MEZZ_HULU_1925782_646/master_cmaf.m3u8")!
    ]
    
    func getInterstitialEvent(forDuration duration: TimeInterval, resumeOffset: TimeInterval? = nil) -> HLSInterstitialEvent {
        let durationPlusOne = duration + 1 // Give a little space for over-filling by a small amount.
        let numberOfAds = Int(durationPlusOne / adDuration)
        var adURLs = [URL]()
        for index in 0..<numberOfAds {
            adURLs.append(urls[index % 2])
        }
        return  HLSInterstitialEvent(
            urls: adURLs,
            resumeOffset: resumeOffset,
            restrictions: [.restrictJump, .restrictSkip]
        )
    }
}
