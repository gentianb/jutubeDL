//
//  PlaylistTableViewCell.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 5/27/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit

class JDLAudioFilesListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var backgroundUIView: UIView!
    @IBOutlet weak var artWorkImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundUIView.layer.cornerRadius = 12.0
        backgroundUIView.layer.backgroundColor = UIColor(red:0.13, green:0.13, blue:0.13, alpha:1.0).cgColor
        backgroundUIView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        backgroundUIView.layer.backgroundColor = UIColor(red:0.13, green:0.13, blue:0.13, alpha:1.0).cgColor
    }

    func updateCellView(with name: String, and image: UIImage){
        artWorkImage.image = image
        nameLabel.text = name
    }
}

