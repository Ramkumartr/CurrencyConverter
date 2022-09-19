//
//  NibLoadable.swift
//  CurrencyConverter
//


import UIKit

protocol NibLoadable {
    static var nib:UINib { get }
}

extension NibLoadable where Self: UIView {
    static var nib: UINib {
        let className = String(describing: self)
        return UINib(nibName: className, bundle: Bundle(for: self))
    }
}
