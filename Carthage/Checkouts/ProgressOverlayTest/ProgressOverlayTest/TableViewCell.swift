//
//  TableViewCell.swift
//  ProgressOverlayTest
//
//  Created by xiangkai yin on 16/9/8.
//  Copyright © 2016年 kuailao_2. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

  @IBOutlet weak var demoButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
