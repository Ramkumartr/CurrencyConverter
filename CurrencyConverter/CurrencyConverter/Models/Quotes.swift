//
//  Rates.swift
//  CurrencyConverter
//
//   

//

import Foundation

struct Quotes:Decodable {
    
    
    var timestamp:Date
    var base:String
    var rates:[String:Double]

    enum CodingKeys:String, CodingKey {
        case timestamp
        case base
        case rates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rates = try container.decode([String:Double].self, forKey: .rates)
        base = try container.decode(String.self, forKey: .base)
        let timestampUnix = try container.decode(TimeInterval.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampUnix)
    }
}
