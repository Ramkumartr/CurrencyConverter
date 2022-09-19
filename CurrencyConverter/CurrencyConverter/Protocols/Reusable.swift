//
//  Reusable.swift
//  CurrencyConverter


protocol Reusable {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        let className = String(describing: self)
        return "\(className)"
    }
}
