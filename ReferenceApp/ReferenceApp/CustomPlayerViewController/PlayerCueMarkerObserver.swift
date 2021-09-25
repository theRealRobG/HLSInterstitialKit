//
//  PlayerCueMarkerObserver.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 25/09/2021.
//

import Foundation
import AVFoundation

protocol PlayerCueMarkerObserverDelegate: AnyObject {
    func playerCueMarkerObserver(_ observer: PlayerCueMarkerObserver, didUpdateCueTimes cueTimes: [PlayerCueMarkerObserver.CueMarker])
}

class PlayerCueMarkerObserver {
    weak var delegate: PlayerCueMarkerObserverDelegate?
    weak private(set) var player: AVPlayer?
    private(set) var cueTimes = [CueMarker]()

    private let observerQueue: OperationQueue
    private var eventsChangedObserver: NSObjectProtocol?
    private var currentItemChangedObserver: NSKeyValueObservation?
    private var lastCueTimesUpdate: [CueMarker]?
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
        let times: [CueMarker] = events
            .filter { $0.primaryItem === currentItem }
            .reduce(into: []) { newTimes, event in
                if let date = event.date {
                    newTimes.append(.date(date))
                } else {
                    newTimes.append(.time(event.time))
                }
            }
        updateCueTimes(times)
    }

    private func updateCueTimes(_ times: [CueMarker]) {
        guard lastCueTimesUpdate != times else { return }
        lastCueTimesUpdate = times
        cueTimes = times
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.playerCueMarkerObserver(self, didUpdateCueTimes: times)
        }
    }
}

extension PlayerCueMarkerObserver {
    enum CueMarker: Equatable {
        case date(Date)
        case time(CMTime)

        var dateValue: Date? {
            switch self {
            case .date(let date): return date
            case .time: return nil
            }
        }

        var timeValue: CMTime {
            switch self {
            case .time(let time): return time
            case .date: return .invalid
            }
        }

        func time(usingDateTimePair dateTimePair: (Date?, CMTime)) -> CMTime? {
            switch self {
            case .time(let time):
                return time
            case .date(let date):
                guard let map = dateTimePair.0.map({ DateTimeMap(date: $0, time: dateTimePair.1) }) else { return nil }
                return map.time(forDate: date)
            }
        }
    }

    private struct DateTimeMap {
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
