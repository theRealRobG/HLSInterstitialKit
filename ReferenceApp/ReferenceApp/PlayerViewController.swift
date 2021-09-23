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

extension AVPlayerViewController: PlayerViewController {}
