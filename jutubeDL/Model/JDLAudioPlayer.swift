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
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(_:)), name: .AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())
    }

    
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
            return audioFiles.isEmpty
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
            return JDLAudioFile(path: URL(string: "Empty")!, albumart: #imageLiteral(resourceName: "default-album-image"))
        }else{
            //this produces an error if the user goes imidiatley after launching the app to the JDLAudioFilesVC and taps on a song, and then filters the list and taps on the Now Playing Icon
            // The reason why is because the delegate for updating the view isn't initialized and doesn't get called, so when the JDLNowPlayingVC gets loaded it fetches the wrong file with an out of bounds index.
            if playlistFiles.count < currentlyPlaying{
                return audioFiles[currentlyPlaying]
            }else{
                return playlistFiles[currentlyPlaying]
            }
        }
    }
    var getJDLAudioFile: [JDLAudioFile]{
        return audioFiles
    }
    
    func getCurrentAudioFile() -> JDLAudioFile{
        if playlistFiles.isEmpty{
            return JDLAudioFile(path: URL(string: "Empty")!, albumart: #imageLiteral(resourceName: "default-album-image"))
        }else{
            return audioFiles[currentlyPlaying]
        }
    }
    
    var totalAudioFiles: Int{
            return audioFiles.count
    }
    
    var isPlaying: Bool{
            guard let player = player else{return false}
            print(player.isPlaying)
            return player.isPlaying
    }
    
    var getCurrentAudioTime: TimeInterval{
            guard let player = player else{ return 0 }
            return player.currentTime
    }
    
    var getCurrentAudioDuration: TimeInterval{
            guard let player = player else{ return 0 }
            return player.duration
    }
    
    func setPlaylist(_ playlist: [JDLAudioFile]){
        playlistFiles = playlist
    }
    
    //MARK: - Shuffle Logic
    var isShuffled: Bool{
            return shuffleStatus
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
            return loopStatus
    }
    func setLoopState(_ state: JDLLoop){
        loopStatus = state
    }
    //MARK: - Handle Remote Events
    
    func handleRemoteControlEvents(eventType: UIEvent){
        switch eventType.subtype.rawValue {
        case 103:
            togglePlayPause()
        default:
            return
        }
    }
    
    //MARK: - Audio Player
    
    @objc func togglePlayPause(){
        print("Toggle method")
        guard let player = player else {
            play(with: 0, source: .audioFilesList)
            return
        }
        if isPlaying{
            player.pause()
            jdlNowPlayingVCDelegate?.callUpdateViews(.nowPlayingList)

        }else{
            player.play()
            jdlNowPlayingVCDelegate?.callUpdateViews(.nowPlayingList)
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
                } catch{
                    print(error.localizedDescription)
                    currentlyPlaying -= 1
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
            updateMediaCenter(currentlyPlaying, duration: player!.duration)
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
                
            } catch {
                print(error.localizedDescription)
                currentlyPlaying += 1
                print("AVAudioPlayer init failed")
            }
        }
    }
    
    func play(with index: Int, source: JDLListSource) {
        currentlyPlaying = index
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
        } catch{
            print(error.localizedDescription)
            print("AVAudioPlayer init failed")
        }
    }
    
    func playAt(set time: Float){
        guard let player = player else {return}
        let currentTime = TimeInterval(time * Float(getCurrentAudioDuration))
        player.currentTime = currentTime
        updateMediaCenter(currentlyPlaying, duration: player.duration)
    }
    
    @objc func playFromCommandCenterWithScrub(_ event: MPChangePlaybackPositionCommandEvent) {
        player?.currentTime = event.positionTime
        updateMediaCenter(currentlyPlaying, duration: player!.duration)
    }
    
    internal func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next()
    }
    
    //MARK: - Handle Interruptions a/o Route Changes
    
    @objc func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
        let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                return
        }
        
        //TODO: See why MediaCenter gets the wrong time when headset disconnects
        switch reason {
        case .oldDeviceUnavailable:
            player?.pause()
        default:
            ()
        }
    }

    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        togglePlayPause()
        updateMediaCenter(currentlyPlaying, duration: player.duration)
    }
    //MARK: - MediaInfo Center Setup
    
    private func setUpMediaCenter(){
        isReceivingRemoteControlEvents = true
        print("INSIDE OF MEDIA CENTER")
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()

        //TODO:- Research :  -> MPRemoteCommandHandlerStatus
        
        commandCenter.playCommand.addTarget(self, action: #selector(togglePlayPause))
        commandCenter.pauseCommand.addTarget(self, action: #selector(togglePlayPause))
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(next))
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(previous))
        commandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(self.playFromCommandCenterWithScrub(_:)))
    }

    private func updateMediaCenter(_ index: Int, duration: TimeInterval){
        let image = playlistFiles[index].albumart
        let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
            return image
        })
        print("Media center updated?")
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle : playlistFiles[index].name,
                                                           MPMediaItemPropertyArtwork : artwork,
                                                           MPMediaItemPropertyArtist : playlistFiles[index].name,
                                                           MPMediaItemPropertyPlaybackDuration : duration,
                                                           MPNowPlayingInfoPropertyPlaybackRate : NSNumber(value: 1.0),
                                                           MPNowPlayingInfoPropertyElapsedPlaybackTime : Int(getCurrentAudioTime)]
    }
}
