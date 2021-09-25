//
//  PlayerCueMarkerObserver.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 25/09/2021.
//

import Foundation
import AVFoundation

protocol PlayerCueMarkerObserverDelegate: AnyObject {
    func playerCueMarkerObserver(_ observer: PlayerCueMarkerObserver, didUpdateCueTimes cueTimes: [CMTime])
}

class PlayerCueMarkerObserver {
    weak var delegate: PlayerCueMarkerObserverDelegate?
    weak private(set) var player: AVPlayer?
    private(set) var cueTimes = [CMTime]()

    private let observerQueue: OperationQueue
    private var eventsChangedObserver: NSObjectProtocol?
    private var currentItemChangedObserver: NSKeyValueObservation?
    private var lastCueTimesUpdate: [CMTime]?
    private var knownEvents = [AVPlayerInterstitialEvent]() {
        didSet { recalculateCueTimes(knownEvents) }
    }

    init(player: AVPlayer) {
        self.player = player
        let dispatchQueue = DispatchQueue(label: "com.cvt.interstitials.player-cue-marker-observer")
        observerQueue = OperationQueue()
        observerQueue.underlyingQueue = dispatchQueue
        eventsChangedObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerInterstitialEventMonitor.eventsDidChangeNotification,
            object: nil,
            queue: observerQueue
        ) { [weak self] notification in
            guard let eventMonitor = notification.object as? AVPlayerInterstitialEventMonitor else { return }
            guard let player = self?.player else { return }
            guard eventMonitor.primaryPlayer === player else { return }
            self?.knownEvents = eventMonitor.events
        }
        currentItemChangedObserver = player.observe(\.currentItem) { [weak self] _, _ in
            guard let self = self else { return }
            self.recalculateCueTimes(self.knownEvents)
        }
    }

    deinit {
        eventsChangedObserver.map { NotificationCenter.default.removeObserver($0) }
        currentItemChangedObserver?.invalidate()
    }

    private func recalculateCueTimes(_ events: [AVPlayerInterstitialEvent]) {
        guard let currentItem = player?.currentItem else {
            updateCueTimes([])
            return
        }
        let currentDate = currentItem.currentDate()
        let currentTime = currentItem.currentTime()
        let dateTimeMap = currentDate.map { DateTimeMap(date: $0, time: currentTime) }
        let times: [CMTime] = events
            .filter { $0.primaryItem === currentItem }
            .reduce(into: []) { newTimes, event in
                if let date = event.date {
                    guard let map = dateTimeMap else { return }
                    newTimes.append(map.time(forDate: date))
                } else {
                    newTimes.append(event.time)
                }
            }
        updateCueTimes(times)
    }

    private func updateCueTimes(_ times: [CMTime]) {
        guard lastCueTimesUpdate != times else { return }
        lastCueTimesUpdate = times
        cueTimes = times
        delegate?.playerCueMarkerObserver(self, didUpdateCueTimes: times)
    }
}

private extension PlayerCueMarkerObserver {
    struct DateTimeMap {
        let date: Date
        let time: CMTime

        func date(forTime: CMTime) -> Date {
            let diff = forTime - time
            return date.addingTimeInterval(diff.seconds)
        }

        func time(forDate: Date) -> CMTime {
            let diff = date.timeIntervalSince(forDate)
            return time - CMTime(seconds: diff, preferredTimescale: 1)
        }
    }
}

