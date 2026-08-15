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
        let request = NSMutableURLRequest(url: URL(string: "https://sandbox-rest.ably.io:443/apps")!)
        request.httpMethod = "POST"
        request.httpBody = "{\"keys\":[{}]}".data(using: String.Encoding.utf8)
        request.allHTTPHeaderFields = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]

        func postSandboxApp() throws -> Data {
            var result: Result<Data, Error> = .failure(URLError(.timedOut))
            let requestCompleted = DispatchSemaphore(value: 0)
            URLSession.shared.dataTask(with: request as URLRequest) { data, _, error in
                if let data {
                    result = .success(data)
                } else {
                    result = .failure(error ?? URLError(.unknown))
                }
                requestCompleted.signal()
            }.resume()
            _ = requestCompleted.wait(timeout: .now() + 15)
            return try result.get()
        }

        // Retries against transient network stalls on CI; safe for the non-idempotent POST because
        // an orphaned app from a timed-out create is auto-deleted by the sandbox after a few
        // minutes of no use. (Local copy of the package's `withProvisioningRetriesSync` — this
        // example project cannot import the package's test targets.)
        func withRetries<T>(_ body: () throws -> T) throws -> T {
            for attempt in 0 ..< 4 {
                do {
                    return try body()
                } catch {
                    Thread.sleep(forTimeInterval: 0.5 * Double(1 << attempt))
                }
            }
            return try body()
        }

        let responseData: Data
        do {
            responseData = try withRetries(postSandboxApp)
        } catch {
            XCTFail("Error setting up sandbox app: \(error)")
            return
        }

        guard let key = (try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions(rawValue: 0)))
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
                do { backgroundRealtimeExpectation.fulfill() }
            }
        } .resume()
        self.waitForExpectations(timeout: 10, handler: nil)

        let backgroundRestExpectation = self.expectation(description: "Rest in a Background Queue")
        var rest: ARTRest! //strong reference
        URLSession.shared.dataTask(with: URL(string: "https://ably.io")!) { _,_,_  in
            rest = ARTRest(key: key as String)
            rest.channels.get("foo").history { result, error in
                do { backgroundRestExpectation.fulfill() }
            }
        }.resume()
        self.waitForExpectations(timeout: 10, handler: nil)
    }

}
