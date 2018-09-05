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
        searchController.searchBar.barStyle = .black
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
    private func askForConfirmation(_ completion: @escaping (_ input: Bool) -> Void){
        let confirmationAlert = UIAlertController(title: "Confirm Deletion", message: "Do you really want to delete this file?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (action) in
            print("CONFIRMED YES")
            completion(true)
        }
        let noAction = UIAlertAction(title: "No", style: .cancel) { (action) in
            completion(false)
        }
        confirmationAlert.addAction(yesAction)
        confirmationAlert.addAction(noAction)

        self.present(confirmationAlert, animated: true)
    }
    private func showWarning(){
        let warningAlert = UIAlertController(title: "", message: "You now have no files. You will be redirected to the download page.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            self.tabBarController?.selectedIndex = 0
            
        }
        
        setTabBarItemsState(true)
        
        warningAlert.addAction(okAction)
        self.present(warningAlert, animated: true)
    }
    
    //MARK: - UI
    private func setTabBarItemsState(_ state: Bool){
        self.tabBarController?.tabBar.items![1].isEnabled = !state
        self.tabBarController?.tabBar.items![2].isEnabled = !state
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
        if !(searchController.searchBar.text?.isEmpty)!{
            instance.setPlaylist(audioFiles)
            print("SEARCH BAR IS ACTIVE SO WE Set the plAYLIST TO THE FILTERED ONE")
        }else{
            instance.setPlaylist(audioFiles)
        }
        
        if audioFiles.count != instance.totalAudioFiles{
            instance.play(with: indexPath.row, source: .nowPlayingList)
        }else{
            instance.play(with: indexPath.row, source: .audioFilesList)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    //MARK: Edit Row Actions
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAudioFileAction = UITableViewRowAction(style: .destructive, title: "DELETE") { (rowAction, indexPath) in
            print("DELETING SONG...")
            self.askForConfirmation({ (confirmation) in
                if confirmation{
                    //-------
                    self.instance.deleteAudioFileAt(path: self.audioFiles[indexPath.row].path, completion: { (hasDeleted) in
                        if hasDeleted{
                            print("sucessfully deleted")
                            self.show(message: "Success")
                            self.audioFiles = JDLAudioPlayer.instance.getJDLAudioFile
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                            
                            if self.instance.isListEmpty{
                                self.showWarning()
                            }
                        }else{
                            self.show(message: "Error occurred")
                        }
                    //-------
                    })
                }
            })

        }
        let addToQueuAction = UITableViewRowAction(style: .default, title: "ADD TO QUEUE") { (rowAction, indexPath) in
            self.instance.addToQueue(self.audioFiles[indexPath.row])
            self.show(message: "Song added.")
            print("ADDING TO QUEUE")
        }
        addToQueuAction.backgroundColor = UIColor(red:0.00, green:0.52, blue:0.26, alpha:1.0)
        //FIXME: Need to find out the relationship between searchController while active and presenting a UIAlert
        if !(searchController.searchBar.text?.isEmpty)!{
            return [addToQueuAction]
        }
        return [addToQueuAction, deleteAudioFileAction]
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
            print("SEARCH DONE OR EMPTY!")
        }else{
                audioFiles = instance.getJDLAudioFile
            audioFiles = audioFiles.filter { (audio : JDLAudioFile) -> Bool in
                audio.name.lowercased().contains(search.lowercased())
            }
        }
        tableView.reloadData()
    }
}

