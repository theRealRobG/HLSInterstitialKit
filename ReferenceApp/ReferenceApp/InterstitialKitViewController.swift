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
    private var interstitialMonitor: AVPlayerInterstitialEventMonitor?

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
        if let player = playerController.player {
            setUpInterstitialMonitor(forPlayer: player)
        }
        present(playerController, animated: true) { playerController.player?.play() }
    }

    private func setUpInterstitialMonitor(forPlayer player: AVPlayer) {
        print("ROBLOG - setting up interstitial monitor")
        let interstitialMonitor = AVPlayerInterstitialEventMonitor(primaryPlayer: player)
        self.interstitialMonitor = interstitialMonitor
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(interstitialEventsDidChange(_:)),
            name: AVPlayerInterstitialEventMonitor.eventsDidChangeNotification,
            object: nil
        )
        if #available(iOS 16.4, tvOS 16.4, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(assetListResponseStatusDidChangeNotification(_:)),
                name: AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeNotification,
                object: nil
            )
        }
    }

    @objc
    private func interstitialEventsDidChange(_ notification: Notification) {
        guard let interstitialMonitor else { return }
        let ids = interstitialMonitor.events.map { $0.identifier }
        if #available(iOS 16.4, tvOS 16.4, *) {
            let assetListResponses = interstitialMonitor
                .events
                .map { event in
                    if let assetListResponse = event.assetListResponse {
                        return "\(assetListResponse)"
                    } else {
                        return "NO RESPONSE"
                    }
                }
            print("ROBLOG - interstitial events did change - \(ids) - \(assetListResponses)")
        } else {
            print("ROBLOG - interstitial events did change - \(ids)")
        }
    }

    @objc @available(iOS 16.4, tvOS 16.4, *)
    private func assetListResponseStatusDidChangeNotification(_ notification: Notification) {
        let status = notification.userInfo?[
            AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeStatusKey
        ] as? AVPlayerInterstitialEventAssetListResponseStatus ?? .unavailable
        guard let event = notification.userInfo?[
            AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeEventKey
        ] as? AVPlayerInterstitialEvent else { fatalError("asset list changed with no associated event") }
        let error = notification.userInfo?[
            AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeErrorKey
        ] as? Error
        switch status {
        case .available:
            if let error {
                print("ROBLOG - asset list available for ID=\"\(event.identifier)\" with error \(error)")
            } else {
                print("ROBLOG - asset list available for ID=\"\(event.identifier)\"")
            }
            if let assetList = event.assetListResponse {
                print("ROBLOG - asset list: \(assetList)")
            }
        case .cleared:
            if let error {
                print("ROBLOG - asset list was cleared for ID=\"\(event.identifier)\" due to \(error)")
            } else {
                print("ROBLOG - asset list was cleared for ID=\"\(event.identifier)\"")
            }
        case .unavailable:
            if let error {
                print("ROBLOG - asset list is unavailable for ID=\"\(event.identifier)\" due to \(error)")
            } else {
                print("ROBLOG - asset list is unavailable for ID=\"\(event.identifier)\",TIME=\(event.time.seconds)")
            }
        @unknown default:
            if let error {
                print("ROBLOG - unknown asset list status \(status) for ID=\"\(event.identifier)\" with error \(error)")
            } else {
                print("ROBLOG - unknown asset list status \(status) for ID=\"\(event.identifier)\"")
            }
        }
        guard let interstitialMonitor else { return }
        let keys = interstitialMonitor.events.map { event in
            if let assetListResponse = event.assetListResponse {
                return "\(assetListResponse)"
            } else {
                return "NO RESPONSE"
            }
        }
        print("ROBLOG - events - \(keys)")
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
                assets: preRolls.assets,
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
