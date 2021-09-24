//
//  PlayerViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 16/07/2021.
//

import UIKit
import AVKit

protocol PlayerViewController: UIViewController {
    var player: AVPlayer? { get set }
}

protocol PlayerViewControllerJumpControlDelegate: AnyObject {
    func playerViewController(
        _ playerViewController: PlayerViewControllerJumpControl,
        timeToSeekAfterUserNavigatedFrom oldTime: CMTime,
        to targetTime: CMTime
    ) -> CMTime
}

protocol PlayerViewControllerJumpControl: PlayerViewController {
    var delegate: PlayerViewControllerJumpControlDelegate? { get set }
}

extension AVPlayerViewController: PlayerViewController {}
