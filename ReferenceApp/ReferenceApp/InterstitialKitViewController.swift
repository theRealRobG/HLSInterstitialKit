//
//  InterstitialKitViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 11/04/2021.
//

import UIKit
import AVKit
import HLSInterstitialKit

class InterstitialKitViewController: UIViewController {
    let vodURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!
    let liveURL = URL(string: "https://live.unified-streaming.com/scte35/scte35.isml/master.m3u8?hls_fmp4")!
    var interstitial: HLSInterstitialInitialEvent {
        HLSInterstitialInitialEvent(
            event: advertService.getInterstitialEvent(forDuration: 30, resumeOffset: .zero),
            startTime: 10
        )
    }
    
    private let advertService = AdvertService()
    private var eventObserver: HLSInterstitialAssetEventObserver?
    
    @IBAction func onPlay(_ sender: Any) {
        play(url: vodURL)
    }
    
    @IBAction func onPlayLive(_ sender: Any) {
        play(url: liveURL)
    }
    
    func play(url: URL) {
        let asset = HLSInterstitialAsset(url: url, initialEvents: [interstitial])
        eventObserver = HLSInterstitialAssetEventObserver(asset: asset)
        eventObserver?.delegate = self
        let item = AVPlayerItem(asset: asset)
        observe(playerItem: item)
        let player = AVPlayer(playerItem: item)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) { player.play() }
    }
}

extension InterstitialKitViewController: HLSInterstitialAssetEventObserverDelegate {
    func interstitialAssetEventObserver(
        _ observer: HLSInterstitialAssetEventObserver,
        shouldWaitForLoadingOfRequest request: HLSInterstitialEventLoadingRequest
    ) -> Bool {
        let events = request.parameters.reduce(into: [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent]()) { results, parameters in
            guard let scteOut = parameters.scte35Out else { return }
            switch scteOut.spliceCommand {
            case .spliceInsert(let spliceInsert):
                guard let ptsDuration = spliceInsert.scheduledEvent?.breakDuration?.duration else { return }
                let duration = TimeInterval(ptsDuration) / 90000
                let event = advertService.getInterstitialEvent(forDuration: duration)
                results[parameters] = event
            default:
                return
            }
        }
        if events.isEmpty {
            return false
        }
        defer {
            request.finishLoading(withResult: .success(events))
        }
        return true
    }
}
