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
    private var playlistFiles = [JDLAudioFile]()
    private var player: AVAudioPlayer?
    private var currentlyPlaying = 0
    private var isReceivingRemoteControlEvents = false
    private var shuffleStatus = false
    private var loopStatus = JDLLoop.none
    
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
            playlistFiles = audioFiles
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
    //MARK: Fetch list state
    var isListEmpty: Bool{
        get{
            return audioFiles.isEmpty
        }
    }
    
    //MARK: - Get/Set Audio Files
    
    func getAudioFile(for index: Int) -> JDLAudioFile{
        return audioFiles[index]
    }
    func getPlayListFile(for index: Int) -> JDLAudioFile{
        return playlistFiles[index]
    }
    
    func getCurrentPlayListFile() -> JDLAudioFile{
        if playlistFiles.isEmpty{
            return JDLAudioFile(path: URL(string: "test")!, albumart: #imageLiteral(resourceName: "default-album-image"))
        }else{
            return playlistFiles[currentlyPlaying]
        }
    }
    func getCurrentAudioFile() -> JDLAudioFile{
        if playlistFiles.isEmpty{
            return JDLAudioFile(path: URL(string: "test")!, albumart: #imageLiteral(resourceName: "default-album-image"))
        }else{
            return audioFiles[currentlyPlaying]
        }
    }
    
    
    var totalAudioFiles: Int{
        get{
            return audioFiles.count
        }
    }
    var isPlaying: Bool{
        get{
            guard let player = player else{return false}
            print(player.isPlaying)
            return player.isPlaying
        }
    }
    var getCurrentAudioTime: TimeInterval{
        get{
            guard let player = player else{ return 0 }
            return player.currentTime
        }
    }
    var getCurrentAudioDuration: TimeInterval{
        get{
            guard let player = player else{ return 0 }
            return player.duration
        }
    }
    //MARK: - Shuffle Logic
    var isShuffled: Bool{
        get{
            return shuffleStatus
        }
    }
    func setShuffleStatus(_ state: Bool){
        shuffleStatus = state
        shufflePlayList()
    }
    //MARK:  Manage playlist
    private func shufflePlayList(){
        if shuffleStatus{
            currentlyPlaying = 0
            playlistFiles.shuffle()
        }else{
            playlistFiles = audioFiles
        }
    }
    //MARK: - Loop Logic
    var getLoopState: JDLLoop{
        get{
            return loopStatus
        }
    }
    func setLoopState(_ state: JDLLoop){
        loopStatus = state
    }
    
    
    
    //MARK: - Audio Player
    
    @objc func togglePlayPause(){
        guard let player = player else {
            play(with: 0, source: .audioFilesList)
            return
        }
        if isPlaying{
            player.pause()
        }else{
            player.play()
        }
    }
    
    @objc func next(){
        
        switch loopStatus {
        case .all, .none:
            if loopStatus == .all && currentlyPlaying == audioFiles.count-1{
                print("End of playlist, return to 0")
                currentlyPlaying = -1
            }
            if currentlyPlaying < totalAudioFiles-1 {
                do {
                    print("INSIDE NEXT")
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    currentlyPlaying += 1
                    player = try AVAudioPlayer(contentsOf: playlistFiles[currentlyPlaying].path)
                    player!.delegate = self
                    guard let player = player else { return }
                    player.play()
                    updateMediaCenter(currentlyPlaying, duration: player.duration)
                    jdlNowPlayingVCDelegate?.callUpdateViews(JDLListSource.nowPlayingList)
                } catch let error as NSError {
                    print(error.localizedDescription)
                    currentlyPlaying -= 1
                    
                } catch {
                    print("AVAudioPlayer init failed")
                }
            }
        case .one:
            guard let player = player else {return}
            player.currentTime = 0
            player.play()
            updateMediaCenter(currentlyPlaying, duration: player.duration)
        }


    }
    @objc func previous(){
        
        if Int(getCurrentAudioTime) >= 3{
            player!.currentTime = 0
        }else if currentlyPlaying > 0  {
            do {
                print("INSIDE NEXT")
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                currentlyPlaying -= 1
                player = try AVAudioPlayer(contentsOf: playlistFiles[currentlyPlaying].path)
                player!.delegate = self
                guard let player = player else { return }
                player.play()
                updateMediaCenter(currentlyPlaying, duration: player.duration)
                jdlNowPlayingVCDelegate?.callUpdateViews(JDLListSource.nowPlayingList)

            } catch let error as NSError {
                print(error.localizedDescription)
                currentlyPlaying += 1
            } catch {
                print("AVAudioPlayer init failed")
            }
        }
    }
    
    func play(with index: Int, source: JDLListSource) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            if source == .audioFilesList{
                player = try AVAudioPlayer(contentsOf: audioFiles[currentlyPlaying].path)
            }else{
                player = try AVAudioPlayer(contentsOf: playlistFiles[currentlyPlaying].path)
            }
            player!.delegate = self
            guard let player = player else { return }
            player.play()
            if shuffleStatus && source == .audioFilesList{
                jdlNowPlayingVCDelegate?.callUpdateViews(source)
                shufflePlayList()
            }else{
                jdlNowPlayingVCDelegate?.callUpdateViews(source)
            }
            if !isReceivingRemoteControlEvents{
                print("set up media center")
                setUpMediaCenter()
            }
            updateMediaCenter(index, duration: player.duration)
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    func playAt(set time: Float){
        guard let player = player else {return}
        let currentTime = TimeInterval(time * Float(getCurrentAudioDuration))
        player.currentTime = currentTime
        updateMediaCenter(currentlyPlaying, duration: player.duration)
    }
    internal func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next()
    }
    
    //MARK: - MediaInfo Center Setup
    
    private func setUpMediaCenter(){
        isReceivingRemoteControlEvents = true
        print("INSIDE OF MEDIA CENTER")
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget(self, action: #selector(togglePlayPause))
        commandCenter.pauseCommand.addTarget(self, action: #selector(togglePlayPause))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(next))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(previous))
    }
    
    private func updateMediaCenter(_ index: Int, duration: TimeInterval){
        let image = playlistFiles[index].albumart
        let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
            return image
        })
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle : playlistFiles[index].name,
                                                           MPMediaItemPropertyArtwork : artwork,
                                                           MPMediaItemPropertyArtist : playlistFiles[index].name,
                                                           MPMediaItemPropertyPlaybackDuration : duration,
                                                           MPNowPlayingInfoPropertyPlaybackRate : NSNumber(value: 1.0),
                                                           MPNowPlayingInfoPropertyElapsedPlaybackTime : Int(getCurrentAudioTime)]
    }
}
