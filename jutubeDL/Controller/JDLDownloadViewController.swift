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
import WebKit

class JDLDownloadViewController: UIViewController {
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var secondSourceLabel: UILabel!
    
    
    let instance = JDLAudioPlayer.instance
    private var webView: WKWebView!
    
    private var lastYoutubeURL = ""
    private var lastFileURL = URL(string: "")
    private var downloadIsIndeterminate = false
    private var webURL = ""
    private var isJsCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedOutsideOfTxtFields()
        // Do any additional setup after loading the view.
        urlTextField.attributedPlaceholder = NSAttributedString(string: "Enter YT URL", attributes: [NSAttributedStringKey.foregroundColor : UIColor.lightGray])
        
        disableTabBarItemsState(instance.isListEmpty)
        
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
        downloadIsIndeterminate = false
        
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
                //FIXME: Server not working anymore
                //self.fetchDownloadLinkSource2()
                //NEW -----------------------------------
                self.fetchDownloadLinkWithWebView()
                //FIXME: need to add network checkers
            }
        }
    }
    
    func startDownload(audioUrl : String, audioName: String){
        let destination = getDestination(audioName)
        
        Alamofire.download(audioUrl, to: destination).downloadProgress { (progress) in
            if progress.isIndeterminate{
                self.progressLabel.text = "Download failed, please try again."
                self.downloadButton.isEnabled = true
                self.downloadIsIndeterminate = true
            }else{
                self.progressView.progress = Float(progress.fractionCompleted)
                self.progressLabel.text = String(format: "%.2f", progress.fractionCompleted*100)
            }
            if progress.fractionCompleted == 1.0{
                self.progressLabel.text = "Download Completed."
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.downloadButton.isEnabled = true
            }
            }
            .response { (data) in
                if data.error != nil{
                    self.progressLabel.text =  data.error!.localizedDescription
                    print("Download failed.")
                    self.downloadButton.isEnabled = true
                }else{
                    if self.downloadIsIndeterminate{
                        //hotfix
                        print("hotfix dl isIndeterminate true")
                        return
                    }
                    print(data.destinationURL!.path)
                    print(data.destinationURL!.lastPathComponent)
                    let csCopy = CharacterSet(bitmapRepresentation: CharacterSet.urlPathAllowed.bitmapRepresentation)
                    
                    let audioPath = data.destinationURL?.lastPathComponent.addingPercentEncoding(withAllowedCharacters: csCopy)
                    print("DL Completed")
                    print("checking if file exists")
                    if self.instance.fileExistsAt(path: data.destinationURL!.lastPathComponent){
                        //save to core data because the file exists
                        //sometimes this function gets called even when the file isn't downloaded.
                        self.instance.addCoreData(Element: audioPath!)
                    }
                    //JDLAudioPlayer.instance.fetchAudioFiles()
                    self.disableTabBarItemsState(self.instance.isListEmpty)
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
        lastFileURL = fileUrl
        print("THIS IS THE destination:  \(destination)")
        return destination
    }
    
    
    //MARK: - UI
    func disableTabBarItemsState(_ state: Bool){
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
extension JDLDownloadViewController: WKUIDelegate, WKNavigationDelegate{
    
    private func fetchDownloadLinkWithWebView(){
        secondSourceLabel.text = "Trying other source to download..."
        
        print("starting")
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: WKWebViewConfiguration())
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.isHidden = true
        print(view.subviews.count)
        //view = webView
        view.insertSubview(webView, at: 0)
        let webRequest = URLRequest(url: URL(string:"https://ytmp3.cc")!)
        
        webView.load(webRequest)
    }
    internal func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !isJsCalled{
            isJsCalled = true
            print("web did finish loading")
            clickButton()
            return
        }
        print("web did finish loading - IGNORED")

    }
    
    //scripting
    private func clickButton(){
        //let songURL = "https://www.youtube.com/watch?v=GlWjfO30zLM"
        let jsString = "document.getElementById(\"input\").value = \"\(urlTextField.text!)\";document.getElementById(\"submit\").click();"
        
        webView.evaluateJavaScript(jsString) { (anyy, errr) in
            if errr != nil{
                print("error")
                print(errr?.localizedDescription)
            } else{
                print("func loaded?")
                self.secondSourceLabel.text = "Server contacted, waiting for response..."
                self.chechForUrlInButton()
            }
        }
    }
    private func chechForUrlInButton(){
        let viewJS = "document.getElementById(\"download\").attributes[\"href\"].textContent"
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
            print("trying to eval")
            self.webView.evaluateJavaScript(viewJS, completionHandler: { (data, errr) in
                if errr != nil{
                    print(errr?.localizedDescription)
                } else{
                    if data as! String != ""{
                        print(data!)
                        self.webURL = data as! String
                        self.getAudioName()
                        timer.invalidate()
                    }else{
                        print("not found")
                    }
                }
            })
        }
    }
    private func getAudioName(){
        //document.getElementById("title").textContent
        let getName = "document.getElementById(\"title\").textContent;"
        webView.evaluateJavaScript(getName) { (name, errr) in
            if errr != nil{
                print(errr?.localizedDescription)
            }else{
                self.songNameLabel.text = (name as! String)
                self.startDownload(audioUrl: self.webURL, audioName: (name as! String))
                self.secondSourceLabel.text = nil
                self.isJsCalled = false
            }
        }
    }
}
