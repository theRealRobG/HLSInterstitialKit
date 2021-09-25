//
//  CuePointSlider.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 25/09/2021.
//

import UIKit

class CuePointSlider: UISlider {
    var cuePositionValues = [Float]() {
        didSet { updateCuePoints(withValues: cuePositionValues) }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let thumb = UIImage(
            systemName: "circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .white)
        )
        setThumbImage(thumb, for: .normal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCuePoints(withValues: cuePositionValues)
    }

    private let cuePointTag = 6969

    private func updateCuePoints(withValues cuePointPositions: [Float]) {
        let cuePoints = cuePointPositions
            .map { pointView(normalizedValue: CGFloat($0)) }
            .sorted { $0.frame.minX < $1.frame.minX }
        let existingPoints = subviews
            .filter { $0.tag == cuePointTag }
            .sorted { $0.frame.minX < $1.frame.minX }
        let diff = cuePoints
            .difference(from: existingPoints) { $0.frame == $1.frame }
        for change in diff {
            switch change {
            case .insert(_, let element, _):
                insertSubview(element, at: 0)
            case .remove(_, let element, _):
                element.removeFromSuperview()
            }
        }
    }

    private func pointView(normalizedValue: CGFloat) -> UIView {
        let frameXPosition = (bounds.maxX - bounds.minX) * normalizedValue
        let cuePointView = UIView(frame: CGRect(x: frameXPosition, y: (frame.maxY - frame.minY)/2 - 1, width: 4, height: 4))
        cuePointView.layer.cornerRadius = 2
        cuePointView.layer.shadowColor = UIColor.black.cgColor
        cuePointView.layer.shadowOpacity = 0.8
        cuePointView.layer.shadowRadius = 2.5
        cuePointView.layer.shadowOffset = CGSize.zero
        cuePointView.backgroundColor = .orange
        cuePointView.tag = cuePointTag
        return cuePointView
    }
}
