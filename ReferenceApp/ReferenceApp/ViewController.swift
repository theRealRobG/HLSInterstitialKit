//
//  ViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 11/04/2021.
//

import UIKit
import AVKit
import HLSInterstitialKit

class ViewController: UIViewController {
    let primaryURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!
    let interstitial = HLSInterstitialInitialEvent(
        event: HLSInterstitialEvent(
            urls: [
                URL(string: "https://mssl.fwmrm.net/m/1/169843/59/6662075/YVWF0614000H_ENT_MEZZ_HULU_1925786_646/master_cmaf.m3u8")!,
                URL(string: "https://mssl.fwmrm.net/m/1/169843/17/6662161/SBON9969000H_ENT_MEZZ_HULU_1925782_646/master_cmaf.m3u8")!
            ],
            resumeOffset: .zero,
            restrictions: [.restrictJump, .restrictSkip]
        ),
        startTime: 10
    )
    
    @IBAction func onPlay(_ sender: Any) {
        let asset = HLSInterstitialAsset(url: primaryURL, initialEvents: [interstitial])
        let item = AVPlayerItem(asset: asset)
        observe(playerItem: item)
        let player = AVPlayer(playerItem: item)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) { player.play() }
    }
    
    func observe(playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFailToPlayToEndTime(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemNewErrorLogEntry(_:)),
            name: .AVPlayerItemNewErrorLogEntry,
            object: playerItem
        )
    }
    
    @objc
    func itemDidFailToPlayToEndTime(_ notification: Notification) {
        guard notification.object is AVPlayerItem else { return }
        guard let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError else { return }
        print(error)
    }
    
    @objc
    func itemNewErrorLogEntry(_ notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        guard let error = playerItem.errorLog()?.events.first else { return }
        print(error)
    }
}

extension AVPlayerItemErrorLogEvent {
    open override var description: String {
        var summary = "ErrorLogEvent |"
        summary += " errorStatusCode:\(errorStatusCode)"
        summary += " errorDomain:\(errorDomain)"
        if let errorComment = errorComment {
            summary += " errorComment:\(errorComment)"
        }
        if let uri = uri {
            summary += " URI:\(uri)"
        }
        if let date = date {
            summary += " date:\(date)"
        }
        if let serverAddress = serverAddress {
            summary += " serverAddress:\(serverAddress)"
        }
        if let playbackSessionID = playbackSessionID {
            summary += " playbackSessionID:\(playbackSessionID)"
        }
        return summary
    }
}
