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
}
