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
    var interstitial: HLSInterstitialInitialEvent {
        HLSInterstitialInitialEvent(
            event: advertService.getInterstitialEvent(forDuration: 30, resumeOffset: .zero),
            startTime: 10
        )
    }
    
    private let advertService = AdvertService()
    private let playerFactory = PlayerFactory()
    private var eventObserver: HLSInterstitialAssetEventObserver?
    
    @IBAction func onPlay(_ sender: Any) {
        play(url: playerFactory.vodURL)
    }
    
    @IBAction func onPlayLive(_ sender: Any) {
        play(url: playerFactory.liveURL)
    }
    
    func play(url: URL) {
        let asset = HLSInterstitialAsset(url: url, initialEvents: [interstitial])
        eventObserver = HLSInterstitialAssetEventObserver(asset: asset)
        eventObserver?.delegate = self
        let playerController = playerFactory.make(asset: asset, playerType: .custom)
        playerController.player?.currentItem.map { observe(playerItem: $0) }
        present(playerController, animated: true) { playerController.player?.play() }
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
