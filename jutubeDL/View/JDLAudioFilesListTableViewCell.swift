//
//  PlaylistTableViewCell.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 5/27/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit

class JDLAudioFilesListTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var artWorkImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    func updateCellView(with name: String, and image: UIImage){
        artWorkImage.image = image
        nameLabel.text = name
    }
}
