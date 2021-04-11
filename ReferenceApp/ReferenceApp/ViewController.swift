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
            urls: [URL(string: "https://mssl.fwmrm.net/m/1/169843/59/6662075/YVWF0614000H_ENT_MEZZ_HULU_1925786_646/master_cmaf.m3u8")!],
            resumeOffset: .zero,
            restrictions: [.restrictJump, .restrictSkip]
        ),
        startTime: 10
    )
    
    @IBAction func onPlay(_ sender: Any) {
        let asset = HLSInterstitialAsset(url: primaryURL, initialEvents: [interstitial])
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) { player.play() }
    }
}
