//
//  CurrencyTableViewCell.swift
//  CurrencyConverter

import UIKit

class CurrencyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var codeLabel:UILabel!
    @IBOutlet weak var nameLabel:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setValue(data: Currency){
        codeLabel.text = data.code
        nameLabel.text = data.name
    }
}
