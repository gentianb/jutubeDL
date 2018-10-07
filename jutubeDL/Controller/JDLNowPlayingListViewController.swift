//
//  JDLNowPlayingListViewController.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 6/3/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit

class JDLNowPlayingListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    let instance = JDLAudioPlayer.instance
    let audioFiles = JDLAudioPlayer.instance.getPlaylist()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension JDLNowPlayingListViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! JDLNowPlayingListTableViewCell
        cell.updateLabel(audioFiles[indexPath.row].audioName!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioFiles.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        instance.play(with: indexPath.row, source: .nowPlayingList)
        self.dismiss(animated: true, completion: nil)
    }
}
