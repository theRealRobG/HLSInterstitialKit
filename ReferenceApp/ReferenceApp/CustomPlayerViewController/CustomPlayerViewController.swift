//
//  CustomPlayerViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 16/07/2021.
//

import UIKit
import AVFoundation

class CustomPlayerViewController: UIViewController, PlayerViewControllerJumpControl {
    var player: AVPlayer? {
        willSet {
            playerCueMarkerObserver?.delegate = nil
            playerTimeObserver.map { player?.removeTimeObserver($0) }
            seekableRangesObservation?.invalidate()
            timeControlStatusObserver?.invalidate()
            timeControlStatusObserver = nil
        }
        didSet {
            playerView.playerLayer.player = player
            player.map { setUp(player: $0) }
            updateCuePoints(cueTimes: playerCueMarkerObserver?.cueTimes ?? [])
        }
    }
    weak var delegate: PlayerViewControllerJumpControlDelegate?
    
    @IBOutlet weak var playerControls: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var playbackSlider: CuePointSlider!
    @IBOutlet weak var dismissButton: UIButton!

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    private let playerView = CustomPlayerView()
    private var playerCueMarkerObserver: PlayerCueMarkerObserver?
    private var currentItemObservation: NSKeyValueObservation?
    private var seekableRangesObservation: NSKeyValueObservation?
    private let playerTimeObserverQueue = DispatchQueue(label: "player-time-observer")
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var playerTimeObserver: Any?
    private var isPlaybackSliderBeingDragged = false
    private var percentageComplete: Float = 0 {
        didSet {
            guard !isPlaybackSliderBeingDragged else { return }
            DispatchQueue.main.async { [weak self] in
                self?.playbackSlider.value = self?.percentageComplete ?? 0
            }
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.insertSubview(playerView, at: 0)
        playerControls.isHidden = true
        activityIndicator.hidesWhenStopped = true
        playPauseButton.setTitle("", for: .normal)
        dismissButton.setTitle("", for: .normal)
        playPauseButton.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        setPlaybackControlsVisibility()
        let tapVideoRecogniser = UITapGestureRecognizer(target: self, action: #selector(videoTapped(_:)))
        playerView.addGestureRecognizer(tapVideoRecogniser)
        let tapControlsContainerRecogniser = UITapGestureRecognizer(target: self, action: #selector(playerControlsContainerViewTapped(_:)))
        playerControls.addGestureRecognizer(tapControlsContainerRecogniser)
        playPauseButton.addTarget(self, action: #selector(playPauseButtonClicked(_:)), for: .touchUpInside)
        playbackSlider.addTarget(self, action: #selector(onSliderValueChanged(slider:event:)), for: .valueChanged)
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        playerView.frame = view.bounds
        updateCuePoints(cueTimes: playerCueMarkerObserver?.cueTimes ?? [])
        super.viewDidLayoutSubviews()
    }

    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            self?.player = nil
        }
    }

    @objc func videoTapped(_ sender: UIView) {
        DispatchQueue.main.async { [weak self] in
            self?.playerControls.isHidden = false
        }
    }

    @objc func playerControlsContainerViewTapped(_ sender: UIView) {
        DispatchQueue.main.async { [weak self] in
            self?.playerControls.isHidden = true
        }
    }
    
    @objc func playPauseButtonClicked(_ sender: UIButton) {
        guard let player = player else { return }
        switch player.timeControlStatus {
        case .paused: player.play()
        case .playing: player.pause()
        case .waitingToPlayAtSpecifiedRate: break
        @unknown default: break
        }
    }
    
    @objc func onSliderValueChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .moved:
                isPlaybackSliderBeingDragged = true
            case .ended:
                isPlaybackSliderBeingDragged = false
                guard let playerItem = player?.currentItem else { return }
                let time = playerItem.playbackPosition(forPercentageComplete: slider.value)
                let updatedTime = delegate?.playerViewController(self, timeToSeekAfterUserNavigatedFrom: playerItem.currentTime(), to: time) ?? time
                if updatedTime != time {
                    playerItem.seek(to: updatedTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                } else {
                    playerItem.seek(to: updatedTime, completionHandler: nil)
                }
            default:
                break
            }
        }
    }
    
    private func setUp(player: AVPlayer) {
        playerTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 2),
            queue: playerTimeObserverQueue
        ) { [weak self, weak player] position in
            guard let self = self, let item = player?.currentItem else { return }
            self.percentageComplete = item.percentageComplete(forPlaybackTime: position)
        }
        timeControlStatusObserver = player.observe(\.timeControlStatus) { [weak self] player, _ in
            DispatchQueue.main.async { [weak self] in
                self?.setPlaybackControlsVisibility()
            }
        }
        playerCueMarkerObserver = PlayerCueMarkerObserver(player: player)
        playerCueMarkerObserver?.delegate = self
        let itemChangedCompletion = { [weak self] in
            guard let self = self, let currentItem = self.player?.currentItem else { return }
            self.seekableRangesObservation = currentItem.observe(\.seekableTimeRanges) { [weak self] _, _ in
                self?.updateCuePoints(cueTimes: self?.playerCueMarkerObserver?.cueTimes ?? [])
            }
        }
        currentItemObservation = player.observe(\.currentItem) { _, _ in itemChangedCompletion() }
        itemChangedCompletion()
    }
    
    private func setPlaybackControlsVisibility() {
        guard let player = self.player else { return }
        switch player.timeControlStatus {
        case .paused:
            setPlaybackControlsStatus(.paused)
        case .waitingToPlayAtSpecifiedRate:
            guard let waitingReason = player.reasonForWaitingToPlay else {
                setPlaybackControlsStatus(.loading)
                return
            }
            switch waitingReason {
            case .noItemToPlay, .toMinimizeStalls, .evaluatingBufferingRate:
                setPlaybackControlsStatus(.loading)
            default:
                if #available(iOS 15, *) {
                    if waitingReason == .interstitialEvent {
                        setPlaybackControlsStatus(.hidden)
                    } else if waitingReason == .waitingForCoordinatedPlayback {
                        setPlaybackControlsStatus(.loading)
                    }
                } else {
                    setPlaybackControlsStatus(.loading)
                }
            }
        case .playing:
            setPlaybackControlsStatus(.playing)
        @unknown default:
            setPlaybackControlsStatus(.playing)
        }
    }
    
    private func setPlaybackControlsStatus(_ status: PlaybackControlsStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch status {
            case .playing:
                self.activityIndicator.stopAnimating()
                let pauseImage = UIImage(systemName: "pause.fill")
                self.playPauseButton.setImage(pauseImage, for: .normal)
                self.playPauseButton.isHidden = false
            case .paused:
                self.activityIndicator.stopAnimating()
                let playImage = UIImage(systemName: "play.fill")
                self.playPauseButton.setImage(playImage, for: .normal)
                self.playPauseButton.isHidden = false
            case .loading:
                self.playPauseButton.isHidden = true
                self.activityIndicator.startAnimating()
            case .hidden:
                self.playPauseButton.isHidden = true
                self.activityIndicator.stopAnimating()
            }
        }
    }
}

extension CustomPlayerViewController: PlayerCueMarkerObserverDelegate {
    private var cuePointTag: Int { 6969 }

    func playerCueMarkerObserver(_ observer: PlayerCueMarkerObserver, didUpdateCueTimes cueTimes: [CMTime]) {
        updateCuePoints(cueTimes: cueTimes)
    }

    func updateCuePoints(cueTimes: [CMTime]) {
        guard let playbackSlider = playbackSlider else { return }
        guard let currentItem = player?.currentItem, !currentItem.seekableTimeRanges.isEmpty else {
            playbackSlider.cuePositionValues = []
            return
        }
        playbackSlider.cuePositionValues = cueTimes.map { currentItem.percentageComplete(forPlaybackTime: $0) }
    }
}

private extension CustomPlayerViewController {
    enum PlaybackControlsStatus {
        case playing
        case paused
        case loading
        case hidden
    }
}

private extension AVPlayerItem {
    func percentageComplete(forPlaybackTime playbackTime: CMTime) -> Float {
        guard let seekableRange = seekableTimeRanges.last?.timeRangeValue else { return 0 }
        guard seekableRange.start < playbackTime, seekableRange.duration > CMTime(seconds: .zero, preferredTimescale: 1) else {
            return 0
        }
        guard playbackTime < seekableRange.end else {
            return 1
        }
        let relativePosition = playbackTime - seekableRange.start
        return Float(relativePosition.seconds / seekableRange.duration.seconds)
    }
    
    func playbackPosition(forPercentageComplete percentageComplete: Float) -> CMTime {
        guard let seekableRange = seekableTimeRanges.last?.timeRangeValue else { return .zero }
        return seekableRange.start + CMTime(
            seconds: (Double(percentageComplete) * seekableRange.duration.seconds),
            preferredTimescale: seekableRange.end.timescale
        )
    }
}
