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
    
    @IBAction func onPlay(_ sender: Any) {
        let asset = HLSInterstitialAsset(url: primaryURL)
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) { player.play() }
    }
}
