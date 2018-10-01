//
//  ViewController.swift
//  BFRadioPlayer
//
//  Created by bananafish911 on 09/29/2018.
//  Copyright (c) 2018 bananafish911. All rights reserved.
//

import UIKit
import BFRadioPlayer
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var metadataLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var playerStateLabel: UILabel!
    
    let defaultStreamUrl = URL(string: "http://8bit.fm:8000/live")!
    var streamUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.placeholder = defaultStreamUrl.absoluteString
        
        playPauseButton.setTitle("Play", for: .normal)
        playPauseButton.setTitle("Pause", for: .selected)
        
        NotificationCenter.default.addObserver(forName: BFRadioPlayer.Notifications.stateChanged, object: nil, queue: nil) { (n) in
            let state = BFRadioPlayer.shared.state
            self.playerStateLabel.text = "\(state)"
//            self.playPauseButton.isSelected = (state == .playing)
        }
        
        NotificationCenter.default.addObserver(forName: BFRadioPlayer.Notifications.nowPlayingInfoUpdated, object: nil, queue: nil) { (n) in
            self.metadataLabel.text = (BFRadioPlayer.shared.nowPlayingInfo.title ?? "") + (BFRadioPlayer.shared.nowPlayingInfo.artist ?? "")
            self.artworkImageView.image = BFRadioPlayer.shared.nowPlayingInfo.artwork
        }
    }
    
    // MARK: -

    var audioPlayer: AVPlayer?
    @IBAction func playPauseButtonAction(_ sender: UIButton) {      
        if BFRadioPlayer.shared.streamUrl == nil {
            BFRadioPlayer.shared.streamUrl = streamUrl ?? defaultStreamUrl
        }
        if BFRadioPlayer.shared.state == .playing {
            BFRadioPlayer.shared.stop()
        }
        BFRadioPlayer.shared.play()
        
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, let url = URL(string: text) else {
            return false
        }
        textField.resignFirstResponder()
        streamUrl = url
        
        BFRadioPlayer.shared.streamUrl = streamUrl
        
        return true
    }
    
}
