//
//  RequestCaller.swift
//  CurrencyConverter

import Foundation
class RequestCaller {
    
    private lazy var decoder = JSONDecoder()
    private let urlSession:URLSession = URLSession.shared
    
    /// A request call that provide Generic Decodable model
    func call<Model:Decodable>(
        request:URLRequest,
        completion: @escaping(Result<Model, CCRequestError>) -> Void) {
        
        let task = urlSession.dataTask(with: request) { [weak self] (data, response, error) in
            guard let weakSelf = self else { return }
            // Check if the request was reachable.
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode != 0 else {
                    completion(Result.failure(.unreachable))
                    return
            }
            guard let responseData = data else {
                fatalError("""
                  We're expecting a data to decode.
                  Response must not be empty!
                  Else it's better to use a different method that doesn't Decode the response object for better result.
                """)
            }
            do {
                if let obj = try? weakSelf.decoder.decode(Model.self, from: responseData) {
                    completion(Result.success(obj))
                } else {
                    // then may be it's the error info.
                    let errObj = try weakSelf.decoder.decode(ErrorDetail.self, from: responseData)
                    completion(Result.failure(CCRequestError.responseError(errObj)))
                }
            } catch {
                // Maybe related to other things like invalid json format and etc.
                completion(Result.failure(CCRequestError.unknownError(error.localizedDescription)))
            }
        }
        task.resume()
    }
}
