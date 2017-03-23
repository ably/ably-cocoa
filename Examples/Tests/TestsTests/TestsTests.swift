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
        var responseData: NSData?

        let postAppExpectation = self.expectationWithDescription("POST app to sandbox")
        let request = NSMutableURLRequest(URL: NSURL(string: "https://sandbox-rest.ably.io:443/apps")!)
        request.HTTPMethod = "POST"
        request.HTTPBody = "{\"keys\":[{}]}".dataUsingEncoding(NSUTF8StringEncoding)
        request.allHTTPHeaderFields = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, _, error in
            defer { postAppExpectation.fulfill() }
            if let e = error {
                XCTFail("Error setting up sandbox app: \(e)")
                return
            }
            responseData = data
        }.resume()
        self.waitForExpectationsWithTimeout(10, handler: nil)

        guard let key = responseData
            .flatMap({ try? NSJSONSerialization.JSONObjectWithData($0, options: NSJSONReadingOptions(rawValue: 0)) })
            .flatMap({ $0 as? NSDictionary })
            .flatMap({ $0["keys"] as? NSArray })
            .flatMap({ $0[0] as? NSDictionary })
            .flatMap({ $0["keyStr"] as? NSString })
        else {
            XCTFail("Expected key in response data, got: \(responseData)")
            return
        }

        let options = ARTClientOptions(key: key as String)
        options.environment = "sandbox"
        let client = ARTRealtime(options: options)

        let receiveExpectation = self.expectationWithDescription("message received")

        client.channels.get("test").subscribe { message in
            XCTAssertEqual(message.data as? NSString, "Get this!")
            client.close()
            receiveExpectation.fulfill()
        }
        
        client.channels.get("test").publish(nil, data: "Get this!")

        self.waitForExpectationsWithTimeout(10, handler: nil)

        let backgroundRealtimeExpectation = self.expectationWithDescription("Realtime in a Background Queue")
        var realtime: ARTRealtime! //strong reference
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string:"https://ably.io")!) { _ in
            realtime = ARTRealtime(key: key as String)
            realtime.channels.get("foo").attach { _ in
                defer { backgroundRealtimeExpectation.fulfill() }
            }
        }.resume()
        self.waitForExpectationsWithTimeout(10, handler: nil)

        let backgroundRestExpectation = self.expectationWithDescription("Rest in a Background Queue")
        var rest: ARTRest! //strong reference
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string:"https://ably.io")!) { _ in
            rest = ARTRest(key: key as String)
            rest.channels.get("foo").history { _ in
                defer { backgroundRestExpectation.fulfill() }
            }
        }.resume()
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
