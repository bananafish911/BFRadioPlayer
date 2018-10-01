//
//  BFRadioPlayer.swift
//  BFRadioPlayer
//
//  Created by Victor on 9/29/18.
//

//**********************************************************************
//
//
//         RadioPlayer - it's the main object in whole app!
//
//
//**********************************************************************

import Foundation
import AVFoundation
import MediaPlayer

open class BFRadioPlayer: NSObject {
    
    public struct Notifications {
        public static let stateChanged = Notification.Name(rawValue: "BFRadioPlayer-stateChanged")
        public static let nowPlayingInfoUpdated = Notification.Name(rawValue: "BFRadioPlayer-nowPlayingInfoUpdated")
        public static let streamUrlChanged = Notification.Name(rawValue: "BFRadioPlayer-streamUrlChanged")
    }
    
    /// Describes audio player state
    ///
    /// - notConfigured:            initial state, or wrong configuration
    /// - paused:                   paused, or ready to play
    /// - playing:                  currently playing
    /// - interruptedAudio:         playback was interrupted by the incomming call or another app, etc.
    /// - interruptedDueInternet:   playback was interrupted due to bad connection
    /// - error:                    has been stopped by some error 
    public enum PlayerState: Int {
        case notConfigured = 0, stopped, paused, playing, interruptedAudio, interruptedDueInternet, error
    }
    
    // MARK: - 
    
    public static let shared = BFRadioPlayer()
    public var isInternetReachable: Bool { return reachability.connection != .none }
    
    public private(set) var state: PlayerState = .notConfigured {
        didSet {
            debugPrint("PlayerState = \(state)")
            NotificationCenter.default.postOnMainQueue(name: Notifications.stateChanged, object: self, userInfo: ["value": state.hashValue])
        }
    }
    
    open var streamUrl: URL? {
        didSet {
            NotificationCenter.default.postOnMainQueue(name: Notifications.streamUrlChanged, object: self, userInfo: ["value": streamUrl ?? ""])
        }
    }
    
    public private(set) var nowPlayingInfo: (title: String?, artist: String?, artwork: UIImage?) {
        didSet {
            let image = nowPlayingInfo.artwork ?? UIImage()
            let info: [String : Any] = [
                MPMediaItemPropertyTitle: nowPlayingInfo.title ?? "",
                MPMediaItemPropertyArtist: nowPlayingInfo.artist ?? "",
                MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: image)
            ]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            NotificationCenter.default.postOnMainQueue(name: Notifications.nowPlayingInfoUpdated, object: self, userInfo: info)
        }
    }
    
    public var loadArtworks = true
    private lazy var artworkGetter = BFArtworkGetter()
    
    private var player = AVPlayer()
    private var playerItem: AVPlayerItem?
    private let reachability = Reachability()!
    
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        registerForReachabilityChanges()
        registerForAVNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        reachability.stopNotifier()
    }
    
    // MARK: -
    
    private func registerForReachabilityChanges() {
        try? reachability.startNotifier()
        NotificationCenter.default.addObserver(forName: .reachabilityChanged) { [unowned self] n in
            if self.isInternetReachable {
                if self.state == .interruptedDueInternet { 
                    self.play()
                }
            } else {
                if self.state == .playing {
                    self.state = .interruptedDueInternet
                    self.player.pause()
                }
            } 
        }
    }
    
    private func registerForAVNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: .AVAudioSessionInterruption) { n in self.audioSessionInterruptionHandler(n) }
        nc.addObserver(forName: .AVAudioSessionRouteChange) { n in self.audioSessionRouteChangeHandler(n) }
        nc.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime) { n in self.playerItemFailedToPlayToEndTimeHandler(n)}
        nc.addObserver(forName: .AVPlayerItemPlaybackStalled) { n in self.playerItemPlaybackStalledHandler(n)}
    }
    
    private func preparePlayerItem(for streamUrl: URL?) {
        guard let streamUrl = streamUrl else { 
            assertionFailure("set stream URL before calling preparePlayerItem()")
            return
        }
        // FIXME not the most elegant way
        objc_sync_enter(self)
        playerItem?.removeObserver(self, forKeyPath: "status", context: nil)
        playerItem?.removeObserver(self, forKeyPath: "timedMetadata", context: nil)
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty", context: nil)
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp", context: nil)
        playerItem = AVPlayerItem(asset: AVAsset(url: streamUrl))
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        playerItem?.addObserver(self, forKeyPath: "timedMetadata", options: [.new], context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new], context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new], context: nil)
        objc_sync_exit(self)
    }
    
    // MARK: - AVAudioSession notifications
    
    private func audioSessionInterruptionHandler(_ notification: Notification) {
        guard let interruption = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? AVAudioSessionInterruptionType else { return }
        switch interruption {
        case .began:
            if state == .playing {
                state = .interruptedAudio
                player.pause()
            }
        case .ended:
            if state == .interruptedAudio {
                play()
            }
        }
    }
    
    private func audioSessionRouteChangeHandler(_ notification: Notification) {
        guard let reasonKey = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteChangeReason else { return }
        if reasonKey == .oldDeviceUnavailable {
            pause()
        }
    }
    
    private var playerItemFailedToPlayToEndTimeRetriesCount: Int = 3
    private func playerItemFailedToPlayToEndTimeHandler(_ notification: Notification) {
        guard playerItemFailedToPlayToEndTimeRetriesCount > 0 else {
            player.pause()
            state = .error
            playerItemFailedToPlayToEndTimeRetriesCount = 3
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            if self.state == .playing {
                self.playerItemFailedToPlayToEndTimeRetriesCount -= 1
                self.play()
            }
        }
    }
    
    private var playerItemPlaybackStalledRetriesCount: Int = 3
    private func playerItemPlaybackStalledHandler(_ notification: Notification) {
        guard playerItemPlaybackStalledRetriesCount > 0 else {
            player.pause()
            state = .error
            playerItemPlaybackStalledRetriesCount = 3
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            if self.state == .playing {
                self.playerItemPlaybackStalledRetriesCount -= 1
                self.play()
            }
        }
    }
    
    // MARK: - AVPlayerItem KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object as? AVPlayerItem, let keyPath = keyPath, item == playerItem else { return }
        
        switch keyPath {
        case "status":
            if item.status != .readyToPlay || !item.isUrlPlayable {
                state = .error
            }
            debugPrint("item.isUrlPlayable \(item.isUrlPlayable)")
        case "timedMetadata":
            kvoTimedMetadataUpdatedHandler(metadata: item.timedMetadata)
        case "playbackBufferEmpty":
            // TODO: check network and play if needed
            debugPrint("kvo playbackBufferEmpty")
        case "playbackLikelyToKeepUp":
            // TODO: retry if stalled
            debugPrint("kvo playbackLikelyToKeepUp")
        default:
            break
        }
    }
    
    private func kvoTimedMetadataUpdatedHandler(metadata: [AVMetadataItem]?) {
        guard let metadata = player.currentItem?.timedMetadata else { return }
        guard let metadataStr = metadata.last?.utf8String else { return }
        
        nowPlayingInfo = (title: metadataStr, artist: nil, artwork: nil)
        artworkGetter.getArtworkImage(query: metadataStr) { (image) in
            self.nowPlayingInfo = (title: metadataStr, artist: nil, artwork: image)
        }
    }
    
    // MARK: - Playback methods
    
    public func play() {
        if playerItem == nil {
            preparePlayerItem(for: streamUrl)
        }
        player.replaceCurrentItem(with: playerItem)
        player.play()
        state = .playing
    }
    
    public func pause() {
        player.pause()
        state = .paused
    }
    
    public func stop() {
        player.replaceCurrentItem(with: nil)
        state = .stopped
    }
    
}
