//
//  JDLAudioPlayer.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 5/29/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer

class JDLAudioPlayer: NSObject, AVAudioPlayerDelegate{
   static let instance = JDLAudioPlayer()
    
    private var audioFiles = [JDLAudioFile]()
    private var player: AVAudioPlayer?
    private var currentlyPlaying = 0
    private var isReceivingRemoteControlEvents = false
    var jdlNowPlayingVCDelegate: JDLNowPlayingVCDelegate?

    
    //MARK: - Fetch Audio Files and process them
    // here we get all of the audio files and store them in an array
    // there reason why im always fetching here instead of appending from the download function
    // Is because sometimes the downloadCompleted response gets triggered without any data being available
    // so until i figure that out this is the way to go
    func fetchAudioFiles(){
        audioFiles.removeAll()
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            
            for url in fileURLs{
                let audioFile = JDLAudioFile(path: url, albumart: getArtwork(audioPath: url))
                audioFiles.append(audioFile)
            }
        }catch {
            print("error accessing files")
        }
    }
    
    private func getArtwork(audioPath: URL) -> UIImage {
        
        let playerItem = AVPlayerItem(url: audioPath)
        let metadataList = playerItem.asset.metadata
        
        for item in metadataList {
            guard let key = item.commonKey, let value = item.value else{
                continue
            }
            if key.rawValue == "artwork"{
                return UIImage(data: (value as! NSData) as Data)!
            }
        }
        return UIImage(named: "default-album-image")!
    }
    //MARK: - Get audioPlayer
    func getAudioFile(for index: Int) -> JDLAudioFile{
        return audioFiles[index]
    }
    func getCurrentAudioFile() -> JDLAudioFile{
        return audioFiles[currentlyPlaying]
    }
    var totalAudioFiles: Int{
        get{
            return audioFiles.count
        }
    }
    var isPlaying: Bool{
        get{
            guard let player = player else{return false}
            return player.isPlaying
        }
    }
    //MARK: - Audio Player
    
    @objc func togglePlayResume(){
        if isPlaying{
            player?.pause()
        }else{
            player?.play()
        }
    }
    @objc func next(){
        print(currentlyPlaying)
        print(totalAudioFiles)
        if currentlyPlaying < totalAudioFiles-1 {
            do {
                print("INSIDE NEXT")
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                currentlyPlaying += 1
                player = try AVAudioPlayer(contentsOf: audioFiles[currentlyPlaying].path)
                player!.delegate = self
                guard let player = player else { return }
                player.play()
                updateMediaCenter(currentlyPlaying, duration: player.duration)
                jdlNowPlayingVCDelegate?.callUpdateViews()
            } catch let error as NSError {
                print(error.localizedDescription)
                currentlyPlaying -= 1

            } catch {
                print("AVAudioPlayer init failed")
            }
        }
    }
    @objc func previous(){
        if currentlyPlaying > 0  {
            do {
                print("INSIDE NEXT")
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                currentlyPlaying -= 1
                player = try AVAudioPlayer(contentsOf: audioFiles[currentlyPlaying].path)
                player!.delegate = self
                guard let player = player else { return }
                player.play()
                updateMediaCenter(currentlyPlaying, duration: player.duration)
                jdlNowPlayingVCDelegate?.callUpdateViews()

            } catch let error as NSError {
                print(error.localizedDescription)
                currentlyPlaying += 1
            } catch {
                print("AVAudioPlayer init failed")
            }
        }
    }
    
    func play(with index: Int) {
        //print("playing \(url)")
        currentlyPlaying = index
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: audioFiles[currentlyPlaying].path)
            player!.delegate = self
            guard let player = player else { return }
            player.play()
            if !isReceivingRemoteControlEvents{
                print("set up media center")
                setUpMediaCenter()
            }
            updateMediaCenter(index, duration: player.duration)
            jdlNowPlayingVCDelegate?.callUpdateViews()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Did finish playing")
        next()
    }
    
    //MARK: - MediaInfo Center Setup
    
    private func setUpMediaCenter(){
        isReceivingRemoteControlEvents = true
        print("INSIDE OF MEDIA CENTER")
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget(self, action: #selector(togglePlayResume))
        commandCenter.pauseCommand.addTarget(self, action: #selector(togglePlayResume))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(next))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(previous))
    }
    
    private func updateMediaCenter(_ index: Int, duration: TimeInterval){
        let image = audioFiles[index].albumart
        let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
            return image
        })
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle : audioFiles[index].name,
                                                           MPMediaItemPropertyArtwork : artwork,
                                                           MPMediaItemPropertyArtist : audioFiles[index].name,
                                                           MPMediaItemPropertyPlaybackDuration : duration,
                                                           MPNowPlayingInfoPropertyPlaybackRate : NSNumber(value: 1.0)]
    }
}
