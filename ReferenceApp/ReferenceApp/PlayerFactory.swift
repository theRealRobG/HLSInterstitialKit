//
//  PlayerFactory.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 16/07/2021.
//

import Foundation
import AVFoundation
import AVKit

struct PlayerFactory {
    let vodURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!
    let liveURL = URL(string: "https://demo.unified-streaming.com/k8s/live/stable/scte35.isml/master.m3u8?hls_fmp4")!
    
    func makeVOD(playerType: PlayerViewControllerType) -> PlayerViewController {
        make(asset: AVURLAsset(url: vodURL), playerType: playerType)
    }
    
    func makeLive(playerType: PlayerViewControllerType) -> PlayerViewController {
        make(asset: AVURLAsset(url: liveURL), playerType: playerType)
    }
    
    func make(asset: AVURLAsset, playerType: PlayerViewControllerType) -> PlayerViewController {
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        let playerViewController: PlayerViewController
        switch playerType {
        case .avKit:
            playerViewController = AVPlayerViewController()
        case .custom:
            #if os(iOS)
            playerViewController = CustomPlayerViewController()
            #else
            fatalError("CustomPlayerViewController does not exist - should not try to use it")
            #endif
        }
        playerViewController.player = player
        return playerViewController
    }
}

extension PlayerFactory {
    enum PlayerViewControllerType: Int {
        case avKit
        case custom
    }
}
