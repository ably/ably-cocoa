//
//  TestsTests.swift
//  TestsTests
//
//  Created by Toni Cárdenas on 11/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import XCTest
import Ably
@testable import Tests

class TestsTests: XCTestCase {

    let options: ARTClientOptions! = nil

    func testAblyWorks() {
        var responseData: Data?

        let postAppExpectation = self.expectation(description: "POST app to sandbox")
        let request = NSMutableURLRequest(url: URL(string: "https://sandbox-rest.ably.io:443/apps")!)
        request.httpMethod = "POST"
        request.httpBody = "{\"keys\":[{}]}".data(using: String.Encoding.utf8)
        request.allHTTPHeaderFields = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]
        URLSession.shared.dataTask(with: request as URLRequest) { data, _, error in
            defer { postAppExpectation.fulfill() }
            if let e = error {
                XCTFail("Error setting up sandbox app: \(e)")
                return
            }
            responseData = data
        }.resume()
        self.waitForExpectations(timeout: 10, handler: nil)

        guard let key = responseData
            .flatMap({ try? JSONSerialization.jsonObject(with: $0, options: JSONSerialization.ReadingOptions(rawValue: 0)) })
            .flatMap({ $0 as? NSDictionary })
            .flatMap({ $0["keys"] as? NSArray })
            .flatMap({ $0[0] as? NSDictionary })
            .flatMap({ $0["keyStr"] as? NSString })
        else {
            XCTFail("Expected key in response data, got: \(String(describing: responseData))")
            return
        }

        let options = ARTClientOptions(key: key as String)
        options.environment = "sandbox"
        let client = ARTRealtime(options: options)

        let receiveExpectation = self.expectation(description: "message received")

        client.channels.get("test").subscribe { message in
            XCTAssertEqual(message.data as? NSString, "Get this!")
            client.close()
            receiveExpectation.fulfill()
        }
        
        client.channels.get("test").publish(nil, data: "Get this!")

        self.waitForExpectations(timeout: 10, handler: nil)

        let backgroundRealtimeExpectation = self.expectation(description: "Realtime in a Background Queue")
        var realtime: ARTRealtime! //strong reference
        URLSession.shared.dataTask(with: URL(string: "https://ably.io")!) { _,_,_  in
            realtime = ARTRealtime(key: key as String)
            realtime.channels.get("foo").attach { _ in
                defer { backgroundRealtimeExpectation.fulfill() }
            }
        } .resume()
        self.waitForExpectations(timeout: 10, handler: nil)

        let backgroundRestExpectation = self.expectation(description: "Rest in a Background Queue")
        var rest: ARTRest! //strong reference
        URLSession.shared.dataTask(with: URL(string: "https://ably.io")!) { _,_,_  in
            rest = ARTRest(key: key as String)
            rest.channels.get("foo").history { result, error in
                defer { backgroundRestExpectation.fulfill() }
            }
        }.resume()
        self.waitForExpectations(timeout: 10, handler: nil)
    }

}
