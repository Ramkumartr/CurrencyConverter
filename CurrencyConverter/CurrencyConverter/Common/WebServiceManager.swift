//
//  WebserviceManager.swift
//  CurrencyConverter
//
//   

//

import Foundation

class WebServiceManager {
    
    static let shared = WebServiceManager()
    
    // static   var config = URLSessionConfiguration.default
    //  static  var urlSession = URLSession(configuration: config)
    let baseUrl:URL = URL(string: WebService_BaseUrl)!
    private lazy var requestCaller = RequestCaller()
    
    /// function to fetch data from the Server
    ///
    /// - Parameters:
    ///   - success: success block
    ///   - failure: failure block
    
    func fetchCurrencies(completion: @escaping(Result<Currencies, CCRequestError>) -> Void) {
        let endpoint = CurrencyList
        requestCaller.call(request: request(from: endpoint), completion: completion)
    }
    
    func fetchLive(source:String, completion: @escaping(Result<Quotes, CCRequestError>) -> Void) {
        let endpoint = CurrencyRates
        requestCaller.call(
            request: request(from: endpoint,
                             queryParams: [base: source]),
            completion: completion)
    }
    
}

extension WebServiceManager {
    
    func request(from endpoint:String, queryParams:[String:String] = [:]) -> URLRequest {
        var components = URLComponents(url: baseUrl.appendingPathComponent(endpoint), resolvingAgainstBaseURL: true)!
        
        var items = [URLQueryItem(name: app_id, value: ACCESSKEY)]
        queryParams.forEach {
            items.append(URLQueryItem(name: $0.key, value: $0.value))
        }
        components.queryItems = items
        return URLRequest(url: components.url!)
    }
    
}
