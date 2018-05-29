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

class JDLAudioPlayer: NSObject{
   static let instance = JDLAudioPlayer()
    
    private var audioFiles = [JDLAudioFile]()
    private var player: AVAudioPlayer?

    
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
    func getNameAndAlbumart(_ index: Int) -> (name: String, albumart: UIImage){
        return (audioFiles[index].name, audioFiles[index].albumart)
    }
    func totalAudioFiles() -> Int{
        return audioFiles.count
    }
    //MARK: - Audio Player
    
    @objc private func playFromMP(){
        player!.play()
    }
    @objc private func pauseFromMP(){
        player!.pause()
    }
    
    func play(with index: Int) {
        //print("playing \(url)")
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: audioFiles[index].path)
            guard let player = player else { return }
            setUpMediaCenter(index, duration: player.duration)
            player.play()
            
            
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    //MARK: - MediaInfo Center Setup
    private func setUpMediaCenter(_ index: Int, duration: TimeInterval){
        let image = audioFiles[index].albumart
        let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
            return image
        })
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle : audioFiles[index].name,
                                                           MPMediaItemPropertyArtwork : artwork,
                                                           MPMediaItemPropertyArtist : audioFiles[index].name,
                                                           MPMediaItemPropertyPlaybackDuration : duration, MPNowPlayingInfoPropertyPlaybackRate : NSNumber(value: 1.0)]
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget(self, action: #selector(playFromMP))
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(pauseFromMP))

    }
}
