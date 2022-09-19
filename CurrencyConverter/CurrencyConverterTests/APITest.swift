//
//  APITest.swift
//  CurrencyConverterTests
//
//   

//

import XCTest

@testable import CurrencyConverter

class APITest: XCTestCase {
    
    let apiService = WebServiceManager()
    
    override func setUp() {
        URLProtocol.registerClass(URLRquestMocker.self)
    }
    
    func testFetchCurrencies() {
        let ex = expectation(description: "must have currencies")
        apiService.fetchCurrencies { result in
            switch result {
            case .success(let value):
                let currencies = value
                XCTAssertEqual(currencies.count, 4)
                XCTAssertEqual(currencies["USD"], "United States Dollar")
                XCTAssertEqual(currencies["JPY"], "Japanese Yen")
                XCTAssertEqual(currencies["AED"], "United Arab Emirates Dirham")
                XCTAssertEqual(currencies["ZWL"], "Zimbabwean Dollar")
            case .failure(let error):
                switch error {
                case .responseError(let detail):
                    XCTFail(detail.description)
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 2.0)
    }
    
    func testFetchQuotes() {
        let ex = expectation(description: "must have quotes")
        apiService.fetchLive(source: "USA") { result in
            switch result {
            case .success(let value):
                let quotes = value.rates
                XCTAssertEqual(quotes.count, 4)
                XCTAssertEqual(quotes["USDAED"], 3.673007)
                XCTAssertEqual(quotes["USDJPY"], 105.760985)
                XCTAssertEqual(quotes["USDUSD"], 1)
                XCTAssertEqual(quotes["USDZWL"], 322.000001)
            case .failure(let error):
                switch error {
                case .responseError(let detail):
                    XCTFail(detail.description)
                default:
                    XCTFail(error.localizedDescription)
                }
            }
            ex.fulfill()
        }
        wait(for: [ex], timeout: 2.0)
    }
    
    override func tearDown() {
        URLProtocol.unregisterClass(URLRquestMocker.self)
    }
    
}
