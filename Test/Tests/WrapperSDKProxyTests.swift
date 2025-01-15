import Ably
import XCTest
import Nimble

class WrapperSDKProxyTests: XCTestCase {
    func testRealtimeAPI() throws {
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        let proxyClient = client.createWrapperSDKProxy(with: .init(agents: ["some-agent": test.id.uuidString]))

        // TODO get these compiling, then start adding other APIs here

        let _ = proxyClient.connection
//
        let channel = proxyClient.channels.get(test.uniqueChannelName())

        channel.attach()
    }

    // MARK: - `request()`

    func test_request_addsWrapperSDKAgentToHeader() throws {
        // Given: a wrapper SDK proxy client
        let test = Test()

        let options = try AblyTests.commonAppSetup(for: test)
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let testHTTPExecutor = TestProxyHTTPExecutor(logger: .init(clientOptions: options))
        realtime.internal.rest.httpExecutor = testHTTPExecutor

        let proxyClient = realtime.createWrapperSDKProxy(with: .init(agents: ["my-wrapper-sdk": "1.0.0"]))

        // When: We call `request(…)` on the wrapper proxy SDK client

        waitUntil(timeout: testTimeout) { done in
            do {
                try proxyClient.request(
                    "GET",
                    path: "/time",
                    params: nil,
                    body: nil,
                    headers: nil
                ) { response, error in
                    XCTAssertNil(error)
                    done()
                }
            } catch {
                XCTFail("request threw error: \(error)")
                done()
            }
        }

        // Then: The HTTP request contains the wrapper SDK's agents in the Ably-Agent header

        let request = try XCTUnwrap(testHTTPExecutor.requests.first)

        let expectedIdentifier = [
            "ably-cocoa/1.2.37",
            ARTDefault.platformAgent(),
            "my-wrapper-sdk/1.0.0"
        ].sorted().joined(separator: " ")
        XCTAssertEqual(request.allHTTPHeaderFields?["Ably-Agent"], expectedIdentifier)
    }

    func test_request_firstAndNext_addWrapperSDKAgentToHeader() throws {
        // Given: a wrapper SDK proxy client
        let test = Test()

        let options = try AblyTests.commonAppSetup(for: test)
        options.testOptions.channelNamePrefix = nil // so that we can just use `channelName` in the `request` call below
        let realtime = ARTRealtime(options: options)
        defer { realtime.dispose(); realtime.close() }

        let testHTTPExecutor = TestProxyHTTPExecutor(logger: .init(clientOptions: options))
        realtime.internal.rest.httpExecutor = testHTTPExecutor

        // Publish some messages so that we can use the history API to fetch them
        let channelName = test.uniqueChannelName()
        let channel = realtime.channels.get(channelName)
        for i in 1...2 {
            waitUntil(timeout: testTimeout) { done in
                channel.publish(nil, data: "\(i)") { error in
                    XCTAssertNil(error)
                    done()
                }
            }
        }

        let proxyClient = realtime.createWrapperSDKProxy(with: .init(agents: ["my-wrapper-sdk": "1.0.0"]))

        // When: We call `request(…)` on the wrapper proxy SDK client and then fetch its `first()` and `next()` pages

        waitUntil(timeout: testTimeout) { done in
            do {
                try proxyClient.request(
                    "GET",
                    path: "/channels/\(channelName)/messages",
                    params: ["limit": "1"],
                    body: nil,
                    headers: nil
                ) { firstPage, error in
                    XCTAssertNil(error)

                    guard let firstPage else {
                        done()
                        return
                    }

                    XCTAssertEqual(firstPage.items.count, 1)

                    firstPage.first { firstPageAgain, error in
                        XCTAssertNil(error)

                        guard let firstPageAgain else {
                            done()
                            return
                        }

                        XCTAssertEqual(firstPageAgain.items.count, 1)

                        firstPageAgain.next { secondPage, error in
                            XCTAssertNil(error)

                            guard let secondPage else {
                                done()
                                return
                            }

                            XCTAssertEqual(secondPage.items.count, 1)

                            done()
                        }
                    }

                }
            } catch {
                XCTFail("request threw error: \(error)")
                done()
            }
        }

        // Then: The HTTP requests all contain the wrapper SDK's agents in the Ably-Agent header

        XCTAssertEqual(testHTTPExecutor.requests.count, 3) // initial `request()`, `first()`, `next()`

        let expectedIdentifier = [
            "ably-cocoa/1.2.37",
            ARTDefault.platformAgent(),
            "my-wrapper-sdk/1.0.0"
        ].sorted().joined(separator: " ")

        for request in testHTTPExecutor.requests {
            XCTAssertEqual(request.allHTTPHeaderFields?["Ably-Agent"], expectedIdentifier)
        }
    }
}
