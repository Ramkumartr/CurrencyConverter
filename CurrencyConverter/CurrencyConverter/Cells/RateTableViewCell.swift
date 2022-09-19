//
//  RateTableViewCell.swift
//  CurrencyConverter

import UIKit

class RateTableViewCell: UITableViewCell {
    @IBOutlet weak var codeLabel:UILabel!
    @IBOutlet weak var valueLabel:UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setValue(data: CalculatedRate){
        codeLabel.text = data.currencyCode
        valueLabel.text = data.value?.stringValue
    }
}
