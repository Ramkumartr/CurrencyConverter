//
//  Common.swift
//  CurrencyConverter


import Foundation
import CoreData

enum CCRequestError:Error, CustomStringConvertible {
    case responseError(ErrorDetail)
    case unknownError(String)
    case unreachable
    
    var description: String {
        switch self {
        case .responseError(let detail):
            return detail.description
        case .unknownError(let msg):
            return msg
        case .unreachable:
            return "Please check your internet connection."
        }
    }
}

struct ErrorDetail:Decodable {
    
    let status:Int
    let description:String
}

//struct ErrorInfo:Error, Decodable {
//    
//    var error: ErrorDetail
//}

public extension NSManagedObject {
    
    convenience init(ctx: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: ctx)!
        self.init(entity: entity, insertInto: ctx)
    }
}

public extension String{
    func isDecimal()->Bool{
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.locale = Locale.current
        return formatter.number(from: self) != nil
    }
}
