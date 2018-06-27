//
//  PlayListViewController.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 5/27/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit

class JDLAudioFilesViewController: UIViewController {
    
    let instance = JDLAudioPlayer.instance
    var audioFiles: [JDLAudioFile]!
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!
    private var localAudioFilesCount = 0

    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedOutsideOfTxtFields()

        audioFiles = JDLAudioPlayer.instance.getJDLAudioFile

        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter"
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = false

        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        
        print("View did load")
        // Do any additional setup after loading the view.
        
    }
    override func viewDidAppear(_ animated: Bool) {
        print(audioFiles.count)
        print(instance.totalAudioFiles)
        print("is localCount == to totalAudioFiles.count")
        print(localAudioFilesCount != instance.totalAudioFiles)
        if localAudioFilesCount != instance.totalAudioFiles{
            audioFiles = instance.getJDLAudioFile
            tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        searchController.isActive = false
        print("dissapear")
    }
}

extension JDLAudioFilesViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        localAudioFilesCount = instance.totalAudioFiles
        return audioFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! JDLAudioFilesListTableViewCell
        let audioData = audioFiles[indexPath.row]
        cell.updateCellView(with: audioData.name, and: audioData.albumart)
        return cell
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if audioFiles.count != instance.totalAudioFiles{
            instance.play(with: indexPath.row, source: .nowPlayingList)
        }else{
            instance.play(with: indexPath.row, source: .audioFilesList)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// MARK: UISearchController
extension JDLAudioFilesViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        print(searchController.searchBar.text!)
        filterAudioFiles(searchString: searchController.searchBar.text!)
    }
    
    func filterAudioFiles(searchString search: String){
        if search == ""{
            audioFiles = instance.getJDLAudioFile
        }else{
            if audioFiles.isEmpty{
                audioFiles = instance.getJDLAudioFile
            }
            audioFiles = audioFiles.filter { (audio : JDLAudioFile) -> Bool in
                audio.name.lowercased().contains(search.lowercased())
            }
        }
        instance.setPlaylist(audioFiles)
        tableView.reloadData()
    }
}
