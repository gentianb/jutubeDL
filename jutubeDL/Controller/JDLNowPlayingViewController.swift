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

    
    private let instance = JDLAudioPlayer.instance
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumArtImage: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded")
        instance.jdlNowPlayingVCDelegate = self
        updateNowPlaying()

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
    @IBAction func nextTrackButtonPressed(_ sender: Any) {
        instance.next()
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
    
}
protocol JDLNowPlayingVCDelegate{
    func callUpdateViews()
}
