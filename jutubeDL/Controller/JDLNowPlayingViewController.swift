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

    
    @IBOutlet weak var blurBG: UIImageView!
    @IBOutlet weak var backgroundAlbumArt: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumArtImage: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var currentAudioTimeLabel: UILabel!
    @IBOutlet weak var totalAudioTimeLabel: UILabel!
    @IBOutlet weak var audioSlider: UISlider!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    
    
    
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
        
        updateNowPlaying(JDLListSource.nowPlayingList)
        startUpdatingSliderAndAudioTime()
        
        // set effect type and view
        let effect = UIBlurEffect(style: .dark)
        let effectView = UIVisualEffectView(effect: effect)

        // set boundry and alpha
        effectView.frame = blurBG.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.alpha = 1.0
        // I first used backgroundAlbumArt for the subview but it's incompatible with UIView.transition so by adding another UIImaveView ontop of it results in a easy workaround
        blurBG.addSubview(effectView)
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
    //MARK: Shuffle
    
    @IBAction func shuffleButtonPressed(_ sender: Any) {
        setShuffleState(instance.isShuffled)
    }
    
    private func setShuffleState(_ state: Bool){
        if state{
            instance.setShuffleStatus(!state)
            shuffleButton.setImage(UIImage(named: "shuffle"), for: .normal)
        }else{
            instance.setShuffleStatus(!state)
            shuffleButton.setImage(UIImage(named: "shuffle_on"), for: .normal)
        }
    }
    //MARK: Loop
    
    @IBAction func repeatButtonPressed(_ sender: Any) {
        checkLoopState()
    }
    private func checkLoopState(){
        switch instance.getLoopState {
        case .none:
            instance.setLoopState(.all)
            repeatButton.setImage(UIImage(named: "repeat_all"), for: .normal)
        case .all:
            instance.setLoopState(.one)
            repeatButton.setImage(UIImage(named: "repeat_one"), for: .normal)
        case .one:
            instance.setLoopState(.none)
            repeatButton.setImage(UIImage(named: "repeat"), for: .normal)
        }
        print(instance.getLoopState)
    }
    
    //MARK: - Protocol Function
    
    func callUpdateViews(_ source: JDLListSource) {
        updateNowPlaying(source)
    }

    //MARK: Update UI
    func updateNowPlaying(_ source: JDLListSource){
        var audioFile: JDLAudioFile
        
        switch source {
        case .nowPlayingList:
             audioFile = instance.getCurrentPlayListFile()
        case .audioFilesList:
             audioFile = instance.getCurrentAudioFile()
        }
        songNameLabel.text = audioFile.name
        updatePlayPauseButton()
        
        if albumArtImage.image! == audioFile.albumart{return}

        UIView.transition(with: self.albumArtImage, duration: 0.4, options: transitionStyle, animations: {
            self.albumArtImage.image = audioFile.albumart
        }, completion: nil)
        
        
        UIView.transition(with: self.backgroundAlbumArt, duration: 1.0, options: [.transitionCrossDissolve, .allowAnimatedContent, .layoutSubviews ], animations: {
            self.backgroundAlbumArt.image = audioFile.albumart
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
            
            let totalMinutes = Int(self.instance.getCurrentAudioDuration-self.instance.getCurrentAudioTime) / 60 % 60
            let totalSeconds = Int(self.instance.getCurrentAudioDuration-self.instance.getCurrentAudioTime) % 60
            
            self.currentAudioTimeLabel.text = String(format:"%2i:%02i", currentMinutes, currentSeconds)
            self.totalAudioTimeLabel.text = String(format:"-%2i:%02i", totalMinutes, totalSeconds)
        }
        timer.fire()
    }
}

protocol JDLNowPlayingVCDelegate{
    func callUpdateViews(_ source: JDLListSource)
}
