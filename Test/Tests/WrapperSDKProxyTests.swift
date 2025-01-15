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
}
