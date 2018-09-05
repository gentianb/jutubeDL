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
    /// Scans for local audio files and reloads the container array.
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
            audioFiles.sort(by: { $0.name < $1.name })
            playlistFiles = audioFiles
        }catch {
            print("error accessing files")
        }
    }

    ///Returns the artwork for the given path. Returns default one if non-existent.
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
    ///Returns boolean indicating presence of audio files.
    var isListEmpty: Bool{
            return audioFiles.isEmpty
    }
    
    //MARK: - Get/Set Audio Files
    ///Returns JDLAudioFile from the main Array.
    func getAudioFile(for index: Int) -> JDLAudioFile{
        return audioFiles[index]
    }
    ///Adds JDLAudioFile to be played next.
    func addToQueue(_ file: JDLAudioFile){
        print("\(currentlyPlaying) \(playlistFiles.endIndex) \(playlistFiles.count)")
        playlistFiles.insert(file, at: currentlyPlaying+1)
    }
    ///Deletes file at given URL.
    func deleteAudioFileAt(path: URL, completion: (_ result: Bool) -> Void){
        let fileManager = FileManager.default
        do{
            try fileManager.removeItem(at: path)
            fetchAudioFiles()
            completion(true)
        }
        catch{
            print(error.localizedDescription)
            completion(false)
        }
    }
    ///
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
    ///Returns the main Audio Files Array.
    var getJDLAudioFile: [JDLAudioFile]{
        return audioFiles
    }
    ///Returns the current playing Audio File.
    func getCurrentAudioFile() -> JDLAudioFile{
        if playlistFiles.isEmpty{
            return JDLAudioFile(path: URL(string: "Empty")!, albumart: #imageLiteral(resourceName: "default-album-image"))
        }else{
            return audioFiles[currentlyPlaying]
        }
    }
    ///Returns an integer indicating the total number of audio files stored.
    var totalAudioFiles: Int{
            return audioFiles.count
    }
    ///Returns a boolean indicating if the player is playing.
    var isPlaying: Bool{
            guard let player = player else{return false}
            print(player.isPlaying)
            return player.isPlaying
    }
    ///Returns the elapsed time for the Audio File.
    var getCurrentAudioTime: TimeInterval{
            guard let player = player else{ return 0 }
            return player.currentTime
    }
    ///Returns the duration for the current AudioFile.
    var getCurrentAudioDuration: TimeInterval{
            guard let player = player else{ return 0 }
            return player.duration
    }
    ///Sets the playlist to the one passed as an argument.
    func setPlaylist(_ playlist: [JDLAudioFile]){
        playlistFiles = playlist
    }
    ///Returns the current playlist.
    func getPlaylist() -> [JDLAudioFile]{
        return playlistFiles
    }
    
    //MARK: - Shuffle Logic
    ///Returns a boolean indicating if the playlist is shuffled.
    var isShuffled: Bool{
            return shuffleStatus
    }
    ///Set the shuffle status. Also shuffles the playlist.
    func setShuffleStatus(_ state: Bool){
        shuffleStatus = state
        shufflePlayList()
    }
    //MARK:  Manage playlist
    ///Shuffles the playlist files.
    private func shufflePlayList(){
        //TODO: Think of how to unshuffle without losing the current playlist combination.
        if shuffleStatus{
            currentlyPlaying = 0
            playlistFiles.shuffle()
        }else{
            playlistFiles = audioFiles
        }
    }
    //MARK: - Loop Logic
    ///Returns the loop state of the player.
    var getLoopState: JDLLoop{
            return loopStatus
    }
    ///Sets the loop state of the player.
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
    ///On call resumes or pauses the player.
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
    
    
    ///Skips to the next song.
    @objc func next(){
        switch loopStatus {
        case .all, .none:
            if loopStatus == .all && currentlyPlaying == playlistFiles.count-1{
                print("End of playlist, return to 0")
                currentlyPlaying = -1
            }
            if currentlyPlaying < playlistFiles.count - 1 {
                do {
                    print("INSIDE NEXT")
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    currentlyPlaying += 1
                    player = try AVAudioPlayer(contentsOf: playlistFiles[currentlyPlaying].path)
                    player!.delegate = self
                    guard let player = player else { return }
                    player.play()
                    updateCommandCenter(currentlyPlaying, duration: player.duration)
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
            updateCommandCenter(currentlyPlaying, duration: player.duration)
        }
    }
    
    //MARK: -
    //TODO: Revise this.
    ///Goes and plays the previous song.
    @objc func previous(){
        if Int(getCurrentAudioTime) >= 3{
            player!.currentTime = 0
            updateCommandCenter(currentlyPlaying, duration: player!.duration)
        }else if currentlyPlaying > 0 && loopStatus != .one  {
                do {
                    print("INSIDE NEXT")
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    try AVAudioSession.sharedInstance().setActive(true)
                    currentlyPlaying -= 1
                    player = try AVAudioPlayer(contentsOf: playlistFiles[currentlyPlaying].path)
                    player!.delegate = self
                    guard let player = player else { return }
                    player.play()
                    updateCommandCenter(currentlyPlaying, duration: player.duration)
                    jdlNowPlayingVCDelegate?.callUpdateViews(JDLListSource.nowPlayingList)
                    
                } catch {
                    print(error.localizedDescription)
                    currentlyPlaying += 1
                    print("AVAudioPlayer init failed")
                }
        }
    }
    //MARK: -
    ///Play audio file with given index, must not be greater than the count of the array.
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
                setUpCommandCenter()
            }
            updateCommandCenter(index, duration: player.duration)
        } catch{
            print(error.localizedDescription)
            print("AVAudioPlayer init failed")
        }
    }
    ///Sets the player at the given time.
    func playAt(set time: Float){
        guard let player = player else {return}
        let currentTime = TimeInterval(time * Float(getCurrentAudioDuration))
        player.currentTime = currentTime
        updateCommandCenter(currentlyPlaying, duration: player.duration)
    }
    
    @objc private func playFromCommandCenterWithScrub(_ event: MPChangePlaybackPositionCommandEvent) {
        player?.currentTime = event.positionTime
        updateCommandCenter(currentlyPlaying, duration: player!.duration)
    }
    
    internal func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next()
    }
    
    //MARK: - Handle Interruptions a/o Route Changes
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
        let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                return
        }
        
        //FIXME: See why MediaCenter gets the wrong time when headset disconnects
        switch reason {
        case .oldDeviceUnavailable:
            player?.pause()
        default:
            ()
        }
    }

    internal func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        togglePlayPause()
        updateCommandCenter(currentlyPlaying, duration: player.duration)
    }
    //MARK: - MediaInfo Center Setup
    ///Initializes Command Center
    private func setUpCommandCenter(){
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
    /// Update Command Center with the actual Audio File Info
    private func updateCommandCenter(_ index: Int, duration: TimeInterval){
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
