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
            var result: Result<Data, Error> = .failure(URLError(.unknown))
            let requestCompleted = DispatchSemaphore(value: 0)
            URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error {
                    result = .failure(error)
                } else if let data, let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) {
                    result = .success(data)
                } else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    result = .failure(NSError(domain: "TestsTests", code: status, userInfo: [
                        NSLocalizedDescriptionKey: "POST /apps returned HTTP \(status)",
                    ]))
                }
                requestCompleted.signal()
            }.resume()
            // Only read `result` when the completion has signalled — on a timeout the handler may
            // still fire later, and reading concurrently with that write would be a data race.
            guard requestCompleted.wait(timeout: .now() + 15) == .success else {
                throw URLError(.timedOut)
            }
            return try result.get()
        }

        // Parses inside the retried path so a transient malformed body engages a retry too. The
        // body is deliberately kept out of the error: a 2xx body can contain valid API keys, and
        // test failures land in public CI logs.
        func provisionSandboxKey() throws -> String {
            let responseData = try postSandboxApp()
            guard let key = (try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions(rawValue: 0)))
                .flatMap({ $0 as? NSDictionary })
                .flatMap({ $0["keys"] as? NSArray })
                .flatMap({ $0.firstObject as? NSDictionary })
                .flatMap({ $0["keyStr"] as? NSString })
            else {
                throw NSError(domain: "TestsTests", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "POST /apps returned a 2xx body with no usable keys (\(responseData.count) bytes)",
                ])
            }
            return key as String
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

        let key: String
        do {
            key = try withRetries(provisionSandboxKey)
        } catch {
            XCTFail("Error setting up sandbox app: \(error)")
            return
        }

        let options = ARTClientOptions(key: key)
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
            realtime = ARTRealtime(key: key)
            realtime.channels.get("foo").attach { _ in
                do { backgroundRealtimeExpectation.fulfill() }
            }
        } .resume()
        self.waitForExpectations(timeout: 10, handler: nil)

        let backgroundRestExpectation = self.expectation(description: "Rest in a Background Queue")
        var rest: ARTRest! //strong reference
        URLSession.shared.dataTask(with: URL(string: "https://ably.io")!) { _,_,_  in
            rest = ARTRest(key: key)
            rest.channels.get("foo").history { result, error in
                do { backgroundRestExpectation.fulfill() }
            }
        }.resume()
        self.waitForExpectations(timeout: 10, handler: nil)
    }

}
