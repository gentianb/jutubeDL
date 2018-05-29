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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedOutsideOfTxtFields()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!

    @IBAction func downloadPressed(_ sender: Any) {
        fetchDownloadLink()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
                self.progressView.progress = Float(progress.fractionCompleted)
            }
            .response { (data) in
                if data.error != nil{
                    print(data.error!.localizedDescription)
                }else{
                    print(data.destinationURL!.path)
                    print("DL Completed")
                    JDLAudioPlayer.instance.fetchAudioFiles()
                }
        }
    }
    
    func fetchDownloadLink(){
        print("Starting")
        Alamofire.request("http://www.convertmp3.io/fetch/?format=JSON&video=\(urlTextField.text!)").responseJSON { (response) in
            if response.result.isSuccess{
                print(response.result.value!)
                let resjson : JSON = JSON(response.result.value!)
                print(resjson["title"].string!)
                self.songNameLabel.text = resjson["title"].string!
                //self.downloadfromURL()
                self.preTest(audioUrl: resjson["link"].string!, audioName: "\(resjson["title"].string!).mp3")
            }else{
                print(response.result.error!)
            }
        }
    }

}
