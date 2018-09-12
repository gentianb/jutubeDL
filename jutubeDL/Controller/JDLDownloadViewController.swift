//
//  JDLDownloadViewController.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 5/27/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON


class JDLDownloadViewController: UIViewController {
    
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var secondSourceLabel: UILabel!

    
    let instance = JDLAudioPlayer.instance
    
    private var lastYoutubeURL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedOutsideOfTxtFields()
        // Do any additional setup after loading the view.
        urlTextField.attributedPlaceholder = NSAttributedString(string: "Enter YT URL", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        setTabBarItemsState(instance.isListEmpty)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkForYTUrl()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - Buttons
    
    @IBAction func downloadPressed(_ sender: Any) {
        if urlTextField.text != ""{
            downloadButton.isEnabled = false
            fetchDownloadLink()
        }
        
    }

    @IBAction func clearButtonPressed(_ sender: Any) {
        urlTextField.text = nil
    }
    
    
    //MARK: - Networking
    func fetchDownloadLink(){
        print("Starting")
        Alamofire.request("http://www.convertmp3.io/fetch/?format=JSON&video=\(urlTextField.text!)").responseJSON { (response) in
            if response.result.isSuccess{
                print(response.result.value!)
                let resjson : JSON = JSON(response.result.value!)
                if resjson["error"].string != nil{
                    self.progressLabel.text = "Invalid URL"
                    self.downloadButton.isEnabled = true
                    return
                }
                print(resjson["title"].string!)
                self.songNameLabel.text = resjson["title"].string!
                //self.downloadfromURL()
                self.startDownload(audioUrl: resjson["link"].string!, audioName: "\(resjson["title"].string!).mp3")
            }else{
                self.progressLabel.text = response.error!.localizedDescription
                //try again with new source
                self.fetchDownloadLinkSource2()
            }
        }
    }
    
    func startDownload(audioUrl : String, audioName: String){
        let destination = getDestination(audioName)
        
        Alamofire.download(audioUrl, to: destination).downloadProgress { (progress) in
                if progress.isIndeterminate{
                    self.progressLabel.text = "Download failed, please try again"
                    self.downloadButton.isEnabled = true
                }else{
                    self.progressView.progress = Float(progress.fractionCompleted)
                    self.progressLabel.text = String(format: "%.2f", progress.fractionCompleted*100)
                }
                if progress.fractionCompleted == 1.0{
                    self.progressLabel.text = "Download Completed"
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.downloadButton.isEnabled = true
                }
            }
            .response { (data) in
                if data.error != nil{
                    self.progressLabel.text =  data.error!.localizedDescription
                    print("Download failed")
                    self.downloadButton.isEnabled = true
                }else{
                    print(data.destinationURL!.path)
                    print("DL Completed")
                    JDLAudioPlayer.instance.fetchAudioFiles()
                    self.setTabBarItemsState(self.instance.isListEmpty)
                }
        }
    }
    
    func fetchDownloadLinkSource2(){
        print("Source 2")
        secondSourceLabel.text = "Trying other source to download..."
        guard let youtubeID = urlTextField.text?.getYoutubeID else { print("couldnt get id") ; return}
        Alamofire.request("https://baixaryoutube.net/@api/json/mp3/\(youtubeID)").responseJSON { (response) in
            if response.result.isSuccess{
                let resJson : JSON = JSON(response.result.value!)
                guard let url = resJson["vidInfo"]["2"]["dloadUrl"].string else {
                    self.secondSourceLabel.text = "Invalid response from server"
                    self.downloadButton.isEnabled = true
                    return
                }
                self.songNameLabel.text = resJson["vidTitle"].string!
                self.startDownload(audioUrl: "https:\(url)", audioName: resJson["vidTitle"].string!+".mp3")
                self.secondSourceLabel.text = nil
            }else{
                self.secondSourceLabel.text = "Server unavailable"
                self.downloadButton.isEnabled = true
            }
        }
    }

    
    
    
    //MARK: Get URL to save file
    func getDestination(_ audioName : String) -> DownloadRequest.DownloadFileDestination{
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileUrl = documentsURL.appendingPathComponent("\(audioName.replacingOccurrences(of: "/", with: ""))")
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileUrl, [.removePreviousFile])}
        print("THIS IS THE fileURL:  \(fileUrl)")
        print("THIS IS THE destination:  \(destination)")
        return destination
    }
    
    
    //MARK: - UI
    func setTabBarItemsState(_ state: Bool){
        self.tabBarController?.tabBar.items![1].isEnabled = !state
        self.tabBarController?.tabBar.items![2].isEnabled = !state
    }
    
    //MARK: - Check for youtube urls
    
    @objc func willEnterForeground(_ notification: NSNotification!) {
        checkForYTUrl()
    }
    
    deinit {
        //remove the observer when this view controller is dismissed/deallocated
        NotificationCenter.default.removeObserver(self)
    }
    
    func checkForYTUrl(){
        guard let youtubeURL = UIPasteboard.general.string?.getYoutubeURL else { return}
        
        if youtubeURL == lastYoutubeURL{
            print("URL was checked before")
            return
        }
        
        lastYoutubeURL = youtubeURL
        
        let actionSheet = UIAlertController(title: "YouTube URL Detected", message: "Would you like to add the link to download?\n \(youtubeURL)", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.urlTextField.text = youtubeURL
            self.fetchDownloadLink()
            self.downloadButton.isEnabled = false
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}
//MARK: - Get Youtube URL or Youtube ID from String

private extension String{
    var getYoutubeURL: String? {
        let pattern = "http(?:s?):\\/\\/(?:www\\.)?youtu(?:be\\.com\\/watch\\?v=|\\.be\\/)([\\w\\-\\_]*)(&(amp;)?‌​[\\w\\?‌​=]*)?"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: count)
        
        guard let result = regex?.firstMatch(in: self, options: [], range: range) else {
            return nil
        }
        return (self as NSString).substring(with: result.range)
}
    var getYoutubeID: String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: count)
        
        guard let result = regex?.firstMatch(in: self, options: [], range: range) else {
            return nil
        }
        return (self as NSString).substring(with: result.range)
    }
    
}
