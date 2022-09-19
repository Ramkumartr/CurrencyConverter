//
//  AlertShowable.swift
//  CurrencyConverter

import UIKit
protocol AlertShowable {
    
    func showAlert(
        title:String?,
        message:String?,
        animated:Bool,
        actions:[UIAlertAction])
}

extension AlertShowable where Self:UIViewController {
    
    func showAlert(
        title:String?,
        message:String?,
        animated:Bool = true,
        actions:[UIAlertAction]) {
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        actions.forEach {
            alert.addAction($0)
        }
        present(alert, animated: animated)
    }
}
