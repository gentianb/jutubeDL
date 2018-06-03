//
//  JDLNowPlayingViewController.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 6/1/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit

class JDLNowPlayingViewController: UIViewController, JDLNowPlayingVCDelegate {

    private let instance = JDLAudioPlayer.instance
    
    var transitionStyle = UIViewAnimationOptions.transitionCrossDissolve

    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumArtImage: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var currentAudioTimeLabel: UILabel!
    @IBOutlet weak var totalAudioTimeLabel: UILabel!
    @IBOutlet weak var audioSlider: UISlider!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioSlider.setThumbImage(UIImage(named: "thumb_normal"), for: .normal)
        audioSlider.setThumbImage(UIImage(named: "thumb_selected"), for: .highlighted)
        audioSlider.isContinuous = false
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(_next))
        leftSwipe.direction = .left
        self.view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(_previous))
        rightSwipe.direction = .right
        self.view.addGestureRecognizer(rightSwipe)
        
        instance.jdlNowPlayingVCDelegate = self
        
        updateNowPlaying()
        startUpdatingSliderAndAudioTime()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Player Buttons
    
    @IBAction func playPauseButtonPressed(_ sender: Any) {
        print("Play pause button pressed")
        instance.togglePlayPause()
        updatePlayPauseButton()
    }
    
    @IBAction func nextTrackButtonPressed(_ sender: Any) {
        transitionStyle = .transitionFlipFromRight
        instance.next()
    }
    
    @objc func _next(){
        transitionStyle = .transitionFlipFromRight
        instance.next()
    }
    
    @objc func _previous(){
        transitionStyle = .transitionFlipFromLeft
        instance.previous()
    }
    
    @IBAction func previousButtonPressed(_ sender: Any) {
        transitionStyle = .transitionFlipFromLeft
        instance.previous()
    }
    //TODO: Implement shuffle logic
    @IBAction func repeatButtonPressed(_ sender: Any) {
    }
    
    @IBAction func shuffleButtonPressed(_ sender: Any) {
    }
    
    //MARK: - Protocol Function
    
    func callUpdateViews() {
        updateNowPlaying()
    }
    //MARK: Update UI
    func updateNowPlaying(){
        let audioFile = instance.getCurrentAudioFile()
        songNameLabel.text = audioFile.name
        updatePlayPauseButton()
        
        UIView.transition(with: self.albumArtImage, duration: 0.4, options: transitionStyle, animations: {
            self.albumArtImage.image = audioFile.albumart
        }, completion: nil)
    }
    
    func updatePlayPauseButton(){
        print("updateplaypause button called")
        
        switch instance.isPlaying {
        case true:
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
        default:
            playPauseButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
    
    //MARK: - Slider Functions
    
    @IBAction func audioSliderDraggingEnded(_ sender: UISlider) {
        instance.playAt(set: sender.value)
    }

    func startUpdatingSliderAndAudioTime(){
        let timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { (time) in
            let sliderValue = self.instance.getCurrentAudioTime / self.instance.getCurrentAudioDuration
            if !self.audioSlider.isHighlighted{
                self.audioSlider.setValue(Float(sliderValue), animated: true)
            }
            let currentMinutes = Int(self.instance.getCurrentAudioTime) / 60 % 60
            let currentSeconds = Int(self.instance.getCurrentAudioTime ) % 60
            
            let totalMinutes = Int(self.instance.getCurrentAudioDuration) / 60 % 60
            let totalSeconds = Int(self.instance.getCurrentAudioDuration) % 60
            
            self.currentAudioTimeLabel.text = String(format:"%2i:%02i", currentMinutes, currentSeconds)
            self.totalAudioTimeLabel.text = String(format:"%2i:%02i", totalMinutes, totalSeconds)
        }
        timer.fire()
    }
}

protocol JDLNowPlayingVCDelegate{
    func callUpdateViews()
}
