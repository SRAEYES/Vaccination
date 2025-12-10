//
//  AgeFilterCell.swift
//  Vaccination
//
//  Created by user66 on 10/12/25.
//

import UIKit

class AgeFilterCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
            // default
            containerView.backgroundColor = UIColor.systemGray6
            titleLabel.textColor = .label
        
        // Initial styling
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        
    }
    
    // call configure on selection change
    func configure(with title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            containerView.backgroundColor = UIColor(red: 0.12, green: 0.53, blue: 0.98, alpha: 1.0) // #1F88FA or use systemBlue
            titleLabel.textColor = .white
        } else {
            containerView.backgroundColor = UIColor.systemGray6
            titleLabel.textColor = .label
        }
    }
}
