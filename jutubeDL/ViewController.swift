//
//  ViewController.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 5/24/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {
    @IBAction func doIT(_ sender: Any) {
        test()
        
    }
    
    
    @IBOutlet weak var songNameLabel: UILabel!
    
    @IBOutlet weak var urlTxtField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBOutlet weak var progressView: UIProgressView!
    override func viewDidAppear(_ animated: Bool) {
         showFiles()
    }
    func showFiles(){
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            plays2(url: fileURLs[1])
            for url in fileURLs{
                let fileName = (url.absoluteString as NSString).lastPathComponent.removingPercentEncoding!
                print(fileName)
            }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
    
    var player :AVAudioPlayer?
    
    func tesst(){
        let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print(docUrl)
    }

    var downloadURL = ""
    var audioFile = Data()
    
    func preTest(audioUrl : String, audioName: String){
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileUrl = documentsURL.appendingPathComponent("\(audioName)")
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileUrl, [.removePreviousFile])
        }
        print("THIS IS THE fileURL:  \(fileUrl)")
        print("THIS IS THE destination:  \(destination)")

        Alamofire.download(audioUrl, to:destination)
            .downloadProgress { (progress) in
                print(progress.fractionCompleted)
                
            }
            .response { (data) in
                if data.error != nil{
                    print(data.error!.localizedDescription)
                }else{
                    print("completed")
                    print(data.destinationURL!.path)
                }
        }
    }
    
    func test(){
        print("Starting")
        Alamofire.request("http://www.convertmp3.io/fetch/?format=JSON&video=\(urlTxtField.text!)").responseJSON { (response) in
            if response.result.isSuccess{
                print(response.result.value!)
                let resjson : JSON = JSON(response.result.value!)
                print(resjson["title"].string!)
                self.downloadURL = resjson["link"].string!
                self.songNameLabel.text = resjson["title"].string!
                //self.downloadfromURL()
                self.preTest(audioUrl: self.downloadURL, audioName: "\(resjson["title"].string!).mp3")
            }else{
                print(response.result.error!)
            }
        }
    }
    
    
    
    func downloadfromURL(){
        Alamofire.request(downloadURL).responseData { (data) in
            if data.result.isSuccess{
                print(data.result.value)
                
                self.audioFile = data.result.value!
                self.plays(dataa: data.result.value!)
            }else{
                print(data.result.error!)
            }
            }.downloadProgress { (progres) in
                self.progressView.progress = Float(progres.fractionCompleted)
        }
//        Alamofire.download(downloadURL).responseData { (data) in
//            if data.result.isSuccess{
//                self.audioFile = data.result.value!
//                self.playSong()
//            }else{
//                print(data.result.error!)
//            }
//
//        }
    }


    func plays(dataa: Data) {
        //print("playing \(url)")
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        
            //player = try AVAudioPlayer(contentsOf: url)
            player = try AVAudioPlayer(data: dataa)
            guard let player = player else { return }
            
            player.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    func plays2(url: URL) {
        //print("playing \(url)")
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.play()
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }


}

