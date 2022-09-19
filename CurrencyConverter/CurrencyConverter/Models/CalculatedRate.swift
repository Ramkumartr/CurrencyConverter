//
//  CalculatedRate.swift
//  CurrencyConverter


import Foundation

struct CalculatedRate {
    var currencyCode:String?
    var value:NSDecimalNumber?
}

extension Rate {
    func equivalentRate(at rate: NSDecimalNumber) -> CalculatedRate {
        return CalculatedRate(currencyCode: currencyCode, value: value?.multiplying(by: rate))
    }
}
