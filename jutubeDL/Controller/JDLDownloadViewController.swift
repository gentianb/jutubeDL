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
    
    let instance = JDLAudioPlayer.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedOutsideOfTxtFields()
        // Do any additional setup after loading the view.
        urlTextField.attributedPlaceholder = NSAttributedString(string: "Enter YT URL", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        setTabBarItemsState(instance.isListEmpty)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func downloadPressed(_ sender: Any) {
        if urlTextField.text != ""{
            fetchDownloadLink()
        }
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
                    return
                }
                print(resjson["title"].string!)
                self.songNameLabel.text = resjson["title"].string!
                //self.downloadfromURL()
                self.startDownload(audioUrl: resjson["link"].string!, audioName: "\(resjson["title"].string!).mp3")
            }else{
                self.progressLabel.text = response.error!.localizedDescription
            }
        }
    }
    
    func startDownload(audioUrl : String, audioName: String){
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileUrl = documentsURL.appendingPathComponent("\(audioName.replacingOccurrences(of: "/", with: ""))")
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileUrl, [.removePreviousFile])
        }
        print("THIS IS THE fileURL:  \(fileUrl)")
        print("THIS IS THE destination:  \(destination)")
        
        Alamofire.download(audioUrl, to:destination)
            .downloadProgress { (progress) in
                if progress.isIndeterminate{
                    self.progressLabel.text = "Download failed, please try again"
                }else{
                    self.progressView.progress = Float(progress.fractionCompleted)
                    self.progressLabel.text = String(format: "%.2f", progress.fractionCompleted*100)
                }
                if progress.fractionCompleted == 1.0{
                    self.progressLabel.text = "Download Completed"
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
            .response { (data) in
                if data.error != nil{
                    self.progressLabel.text =  data.error!.localizedDescription
                }else{
                    print(data.destinationURL!.path)
                    print("DL Completed")
                    JDLAudioPlayer.instance.fetchAudioFiles()
                    self.setTabBarItemsState(self.instance.isListEmpty)
                }
        }
    }
    
    
    //MARK - UI
    func setTabBarItemsState(_ state: Bool){
        self.tabBarController?.tabBar.items![1].isEnabled = !state
        self.tabBarController?.tabBar.items![2].isEnabled = !state
    }
    


}
