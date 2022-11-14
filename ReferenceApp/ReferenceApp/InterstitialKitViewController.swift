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
    var preRolls: HLSInterstitialEvent {
        advertService.getInterstitialPreRoll()
    }
    #if os(iOS)
    @IBOutlet weak var playerControllerPicker: UIPickerView!
    #endif

    private let advertService = AdvertService()
    private let playerFactory = PlayerFactory()
    
    @IBAction func onPlay(_ sender: Any) {
        play(url: playerFactory.vodURL)
    }
    
    @IBAction func onPlayLive(_ sender: Any) {
        play(url: playerFactory.liveURL)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if os(iOS)
        playerControllerPicker.delegate = self
        playerControllerPicker.dataSource = self
        #endif
    }
    
    func play(url: URL) {
        let asset = HLSInterstitialAsset(url: url)
        asset.delegate = self
        #if os(iOS)
        let playerController = playerFactory.make(
            asset: asset,
            playerType: PlayerFactory.PlayerViewControllerType(
                rawValue: playerControllerPicker.selectedRow(inComponent: 0)
            ) ?? .avKit
        )
        #else
        let playerController = playerFactory.make(asset: asset, playerType: .avKit)
        #endif
        playerController.player?.currentItem.map { observe(playerItem: $0) }
        present(playerController, animated: true) { playerController.player?.play() }
    }
}

extension InterstitialKitViewController: HLSInterstitialAssetDelegate {
    func interstitialAsset(
        _ asset: HLSInterstitialAsset,
        shouldWaitForLoadingOfInitialRequest request: HLSInterstitialEventInitialLoadingRequest
    ) -> Bool {
        var preRolls = preRolls
        switch request.playlist.playlistType {
        case .vod:
            preRolls = HLSInterstitialEvent(
                urls: preRolls.urls,
                resumeOffset: .zero,
                snap: preRolls.snap,
                playoutDurationLimit: preRolls.playoutDurationLimit,
                restrictions: preRolls.restrictions,
                cue: preRolls.cue
            )
        case .event, .live, .unknown:
            break
        }
        let events = getEvents(fromRequestParameters: request.parameters)
        defer {
            request.finishLoading(
                withResult: .success(events),
                preRollInterstitials: [preRolls],
                midRollInterstitials: [interstitial]
            )
        }
        return true
    }

    func interstitialAsset(
        _ asset: HLSInterstitialAsset,
        shouldWaitForLoadingOfRequest request: HLSInterstitialEventLoadingRequest
    ) -> Bool {
        let events = getEvents(fromRequestParameters: request.parameters)
        if events.isEmpty {
            return false
        }
        defer {
            request.finishLoading(withResult: .success(events))
        }
        return true
    }

    private func getEvents(
        fromRequestParameters parameters: [HLSInterstitialEventLoadingRequest.Parameters]
    ) -> [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent] {
        parameters.reduce(
            into: [HLSInterstitialEventLoadingRequest.Parameters: HLSInterstitialEvent]()
        ) { results, parameters in
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
    }
}

#if os(iOS)
extension InterstitialKitViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch PlayerFactory.PlayerViewControllerType(rawValue: row) {
        case .avKit, .none: return "AVPlayerViewController"
        case .custom: return "CustomPlayerViewController"
        }
    }
}
#endif
