//
//  CustomPlayerView.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 16/07/2021.
//

import UIKit
import AVFoundation

class CustomPlayerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
