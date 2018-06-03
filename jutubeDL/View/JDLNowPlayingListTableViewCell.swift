//
//  JDLNowPlayingListTableViewCell.swift
//  jutubeDL
//
//  Created by Gentian Barileva on 6/3/18.
//  Copyright © 2018 Gentian Barileva. All rights reserved.
//

import UIKit

class JDLNowPlayingListTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var nameLabel: UILabel!
    
    func updateLabel(_ name: String){
        nameLabel.text = name
    }
}
