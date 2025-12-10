//
//  VaccineCell.swift
//  Vaccination
//
//  Created by user66 on 10/12/25.
//

import UIKit

class VaccineCell: UITableViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        
        // card style
//                cardView.backgroundColor = UIColor(red: 0.86, green: 0.93, blue: 1.00, alpha: 1.0) // #DBECFF
                cardView.layer.cornerRadius = 25
                cardView.clipsToBounds = true

                // cell background must be clear
                contentView.backgroundColor = .clear
                backgroundColor = .clear
                selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(name: String, subtitle: String) {
            titleLabel.text = name
            subtitleLabel.text = subtitle
            titleLabel.textColor = .label
            subtitleLabel.textColor = .secondaryLabel
        }
    
}
