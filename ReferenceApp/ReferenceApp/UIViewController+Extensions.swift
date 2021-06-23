//
//  UIViewController+Extensions.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 23/06/2021.
//

import UIKit
import AVFoundation

extension UIViewController {
    func observe(playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFailToPlayToEndTime(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemNewErrorLogEntry(_:)),
            name: .AVPlayerItemNewErrorLogEntry,
            object: playerItem
        )
    }
    
    @objc
    func itemDidFailToPlayToEndTime(_ notification: Notification) {
        guard notification.object is AVPlayerItem else { return }
        guard let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError else { return }
        print(error)
    }
    
    @objc
    func itemNewErrorLogEntry(_ notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        guard let error = playerItem.errorLog()?.events.first else { return }
        print(error)
    }
}
