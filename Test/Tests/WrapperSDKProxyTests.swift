import Ably
import XCTest
import Nimble

class WrapperSDKProxyTests: XCTestCase {
    // MARK: - Testing that connection state is shared with underlying Realtime client

    func test_sharesConnectionStateWithUnderlyingClient() throws {
        // Given: A proxy client
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.autoConnect = false
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        let proxyClient = client.createWrapperSDKProxy(with: .init(agents: ["some-agent": test.id.uuidString]))

        // (An example of changes to the underlying connection being reflected in the proxy client)
        //
        // When: The underlying connection becomes CONNECTED
        // Then: So does the proxy client
        waitUntil(timeout: testTimeout) { done in
            proxyClient.connection.on(.connected) { _ in
                done()
            }

            client.connect()
        }
        XCTAssertEqual(proxyClient.connection.state, .connected)

        // (An example of the proxy client provoking changes in the underlying connection)
        //
        // When: We call `close()` on the proxy client
        // Then: It closes the underlying connection
        waitUntil(timeout: testTimeout) { done in
            client.connection.on(.closed) { _ in
                done()
            }

            proxyClient.close()
        }
        XCTAssertEqual(client.connection.state, .closed)
    }

    func test_sharesConnectionSubscriptionsWithUnderlyingRealtimeClient() throws {
        // Given: A proxy client
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.autoConnect = false
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        let proxyClient = client.createWrapperSDKProxy(with: .init(agents: ["some-agent": test.id.uuidString]))

        // When: We add a connection event listener to the underlying client, then call `off()` on the proxy client and provoke a connection event
        var underlyingConnectionReceivedEvent = false
        client.connection.on(.connected) { _ in
            underlyingConnectionReceivedEvent = true
        }

        proxyClient.connection.off()

        // this is the "provoke a connection event" above
        waitUntil(timeout: testTimeout) { done in
            client.connection.on(.connected) { _ in
                done()
            }
            client.connect()
        }

        // Then: We do not receive the connection event on the aforementioned listener, because calling `off()` on the proxy client removed the listener
        XCTAssertFalse(underlyingConnectionReceivedEvent)
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
