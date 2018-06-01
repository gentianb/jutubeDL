//
//  PlayListViewController.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 5/27/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit

class JDLPlayListViewController: UIViewController {
    
    let instance = JDLAudioPlayer.instance
    @IBOutlet weak var tableView: UITableView!
    private var localAudioFilesCount = 0

    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        print("View did load")
        // Do any additional setup after loading the view.
        
    }
    override func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear")
        print(localAudioFilesCount != instance.totalAudioFiles)
        if localAudioFilesCount != instance.totalAudioFiles{
            tableView.reloadData()
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
extension JDLPlayListViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        localAudioFilesCount = instance.totalAudioFiles
        return instance.totalAudioFiles
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! PlaylistTableViewCell
        let audioData = instance.getAudioFile(for: indexPath.row)
        cell.updateCellView(with: audioData.name, and: audioData.albumart)
        return cell
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        instance.play(with: indexPath.row)
    }
    
    
}
