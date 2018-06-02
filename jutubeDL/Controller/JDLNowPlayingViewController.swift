//
//  JDLNowPlayingViewController.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 6/1/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit
import ChameleonFramework

class JDLNowPlayingViewController: UIViewController, JDLNowPlayingVCDelegate {


    
    @IBAction func swiped(_ sender: Any) {
        print("swiped")
    }
    @objc func swipeee(){
        print("SWIPEEE")
    }
    private let instance = JDLAudioPlayer.instance
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumArtImage: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var currentAudioTimeLabel: UILabel!
    @IBOutlet weak var totalAudioTimeLabel: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        print("View loaded")
        
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

        // Do any additional setup after loading the view.
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    func updateNowPlaying(){
        let audioFile = instance.getCurrentAudioFile()
        songNameLabel.text = audioFile.name
        albumArtImage.image = audioFile.albumart
        updatePlayPauseButton()
//        let colorFromImage = ColorsFromImage(albumArtImage.image!, withFlatScheme: true)
//        view.backgroundColor = UIColor(complementaryFlatColorOf: colorFromImage[2])
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func playPauseButtonPressed(_ sender: Any) {
        print("Play pause button pressed")
        instance.togglePlayResume()
        updatePlayPauseButton()

    }
    @IBOutlet weak var audioSlider: UISlider!
    @IBAction func nextTrackButtonPressed(_ sender: Any) {
        instance.next()
    }
    @objc func _next(){
        instance.next()
    }
    @objc func _previous(){
        instance.previous()
    }
    @IBAction func previousButtonPressed(_ sender: Any) {
        instance.previous()
    }
    @IBAction func repeatButtonPressed(_ sender: Any) {
    }
    @IBAction func shuffleButtonPressed(_ sender: Any) {
    }
    func callUpdateViews() {
        updateNowPlaying()
    }
    
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
