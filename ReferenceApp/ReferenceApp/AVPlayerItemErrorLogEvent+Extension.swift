//
//  AVPlayerItemErrorLogEvent+Extension.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 27/04/2021.
//

import AVFoundation

extension AVPlayerItemErrorLogEvent {
    open override var description: String {
        var summary = "ErrorLogEvent |"
        summary += " errorStatusCode:\(errorStatusCode)"
        summary += " errorDomain:\(errorDomain)"
        if let errorComment = errorComment {
            summary += " errorComment:\(errorComment)"
        }
        if let uri = uri {
            summary += " URI:\(uri)"
        }
        if let date = date {
            summary += " date:\(date)"
        }
        if let serverAddress = serverAddress {
            summary += " serverAddress:\(serverAddress)"
        }
        if let playbackSessionID = playbackSessionID {
            summary += " playbackSessionID:\(playbackSessionID)"
        }
        return summary
    }
}
