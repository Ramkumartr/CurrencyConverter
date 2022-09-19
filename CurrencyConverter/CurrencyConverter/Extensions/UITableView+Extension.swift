//
//  UITableView+Extension.swift
//  CurrencyConverter

import UIKit

extension UITableViewCell:NibLoadable {}
extension UITableViewCell:Reusable {}


extension UITableView {
    
    func register<T: NibLoadable & Reusable >(_ c: T.Type) {
        register(T.nib, forCellReuseIdentifier: T.reuseIdentifier)
    }
    
    func dequeue<T: Reusable>(_ : T.Type) -> T? {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier) as? T
    }
}
