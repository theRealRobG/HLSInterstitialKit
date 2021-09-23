//
//  AVInterstitialViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 23/06/2021.
//

import UIKit
import AVKit
import AVFoundation
import SCTE35Parser

@available(iOS 15, tvOS 15, *)
class AVInterstitialViewController: UIViewController {
    private let collectorQueue = DispatchQueue(label: "com.InterstitialKit.AVInterstitialViewController.collectorQueue")
    private let advertService = AdvertService()
    private let playerFactory = PlayerFactory()
    private var interstitialEventController: AVPlayerInterstitialEventController?
    private var observedItem: ObservedItem?
    
    @IBAction func onPlayVOD(_ sender: Any) {
        play(playerController: playerFactory.makeVOD(playerType: .custom), isVOD: true)
    }
    
    @IBAction func onPlayLive(_ sender: Any) {
        play(playerController: playerFactory.makeLive(playerType: .custom), isVOD: false)
    }
    
    func play(playerController: PlayerViewController, isVOD: Bool) {
        guard let player = playerController.player, let item = player.currentItem else { fatalError() }
        observe(playerItem: item)
        setUpMetadataCollector(forPlayerItem: item)
        let eventController = AVPlayerInterstitialEventController(primaryPlayer: player)
        if isVOD {
            let event = advertService.getAVInterstitialEvent(
                primaryItem: item,
                forTime: 10,
                forDuration: 30,
                resumeOffset: .zero
            )
            eventController.events = [event]
        }
        interstitialEventController = eventController
        present(playerController, animated: true) { player.play() }
    }
    
    private func setUpMetadataCollector(forPlayerItem playerItem: AVPlayerItem) {
        let collector = AVPlayerItemMetadataCollector()
        collector.setDelegate(self, queue: collectorQueue)
        playerItem.add(collector)
        observedItem = ObservedItem(playerItem: playerItem, metadataCollector: collector)
    }
}

@available(iOS 15, tvOS 15, *)
extension AVInterstitialViewController: AVPlayerItemMetadataCollectorPushDelegate {
    func metadataCollector(
        _ metadataCollector: AVPlayerItemMetadataCollector,
        didCollect metadataGroups: [AVDateRangeMetadataGroup],
        indexesOfNewGroups: IndexSet, indexesOfModifiedGroups: IndexSet
    ) {
        guard
            let observedItem = self.observedItem,
            observedItem.metadataCollector == metadataCollector,
            let eventController = interstitialEventController
        else {
            return
        }
        let newGroups = indexesOfNewGroups
            .filteredIndexSet { metadataGroups.indicies(containsIndex: $0) }
            .map { metadataGroups[$0] }
        let events: [AVPlayerInterstitialEvent] = newGroups.compactMap { metadataGroup in
            guard
                let scteOutItem = metadataGroup.items.first(where: { ($0.key as? String) == "SCTE35-OUT" }),
                let scteOut = scteOutItem.dataValue,
                let spliceInfo = try? SpliceInfoSection(data: scteOut)
            else {
                return nil
            }
            switch spliceInfo.spliceCommand {
            case .spliceInsert(let spliceInsert):
                guard let ptsDuration = spliceInsert.scheduledEvent?.breakDuration?.duration else { return nil }
                let duration = TimeInterval(ptsDuration) / 90000
                return advertService.getAVInterstitialEvent(
                    primaryItem: observedItem.playerItem,
                    forDate: metadataGroup.startDate,
                    forDuration: duration
                )
            default:
                return nil
            }
        }
        print("scheduled events \(events.count) - \(events.map { $0.identifier })")
        eventController.events = events
    }
}

@available(iOS 15, tvOS 15, *)
private extension AVInterstitialViewController {
    struct ObservedItem {
        let playerItem: AVPlayerItem
        let metadataCollector: AVPlayerItemMetadataCollector
    }
}
