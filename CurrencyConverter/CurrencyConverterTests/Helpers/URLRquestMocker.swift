//
//  URLRquestMocker.swift
//  CurrencyConverterTests
//
//   

//


import Foundation

class URLRquestMocker:URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let path = request.url?.path,
              let mockUrl = urlOfFile(endpoint: path),
              let mockData = try? Data(contentsOf: mockUrl) else { return }
        
        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: 200, // TODO: Assume only Success for now,since we only fetch data for now. BUT this must be changed.
            httpVersion: nil,
            headerFields: nil)!
        
        client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mockData)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        
    }
    
    private func urlOfFile(endpoint:String) -> URL? {
        
        
        var fileName = endpoint.replacingOccurrences(of: "/api/", with: "")
        fileName = fileName.replacingOccurrences(of: ".json", with: "")
        
        let testBundle = Bundle(for: type(of: self))
        guard let path = testBundle.path(forResource: fileName, ofType: "json") else {
            fatalError("Cannot find the mock-resources folder")
            
        }
        
        return URL(fileURLWithPath: path)
        
    }
    
}
