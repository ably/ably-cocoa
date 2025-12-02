import Ably.Private
import XCTest
import _AblyPluginSupportPrivate
import Nimble

class PluginAPITests: XCTestCase {
    // MARK: - Mocks

    class MockLiveObjectsPlugin: NSObject, _AblyPluginSupportPrivate.LiveObjectsPluginProtocol {
        static let _internalPlugin = MockInternalLiveObjectsPlugin()

        static func internalPlugin() -> any LiveObjectsInternalPluginProtocol {
            _internalPlugin
        }
    }

    class MockInternalLiveObjectsPlugin: NSObject, _AblyPluginSupportPrivate.LiveObjectsInternalPluginProtocol {
        internal var receivedConnectionDetails: [(connectionDetails: (any ConnectionDetailsProtocol)?, channel: any RealtimeChannel)] = []

        func nosync_prepare(_ channel: any RealtimeChannel, client: any RealtimeClient) {
            // no-op
        }

        func decodeObjectMessage(_ serialized: [String : Any], context: any DecodingContextProtocol, format: EncodingFormat, error: AutoreleasingUnsafeMutablePointer<(any PublicErrorInfo)?>?) -> (any ObjectMessageProtocol)? {
            fatalError("Not yet implemented")
        }

        func encodeObjectMessage(_ objectMessage: any ObjectMessageProtocol, format: EncodingFormat) -> [String : Any] {
            fatalError("Not yet implemented")
        }

        func nosync_onChannelAttached(_ channel: any RealtimeChannel, hasObjects: Bool) {
            fatalError("Not yet implemented")
        }

        func nosync_handleObjectProtocolMessage(withObjectMessages objectMessages: [any ObjectMessageProtocol], channel: any RealtimeChannel) {
            fatalError("Not yet implemented")
        }

        func nosync_handleObjectSyncProtocolMessage(withObjectMessages objectMessages: [any ObjectMessageProtocol], protocolMessageChannelSerial: String?, channel: any RealtimeChannel) {
            fatalError("Not yet implemented")
        }

        func nosync_onConnected(withConnectionDetails connectionDetails: (any ConnectionDetailsProtocol)?, channel: any RealtimeChannel) {
            receivedConnectionDetails.append((connectionDetails, channel))
        }
    }

    // MARK: - Server time

    func test_fetchServerTime() throws {
        // Given: A realtime client
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        var serverTimeRequestCount = 0
        let rest = client.internal.rest
        let hook = rest.testSuite_injectIntoMethod(after: #selector(rest._time(withWrapperSDKAgents:completion:))) {
            serverTimeRequestCount += 1
        }
        defer { hook.remove() }

        let pluginAPI = DependencyStore.sharedInstance().fetchPluginAPI()
        let pluginRealtimeClient = client.internal as! _AblyPluginSupportPrivate.RealtimeClient

        let internalQueue = client.internal.queue

        // When: We call nosync_fetchServerTime twice on the plugin API

        for _ in (1...2) {
            waitUntil(timeout: testTimeout) { done in
                internalQueue.async {
                    pluginAPI.nosync_fetchServerTime(for: pluginRealtimeClient) { serverTime, error in
                        // Then: Both attempts succeed, and the server time is fetched from the REST API on the first attempt but not on the second
                        dispatchPrecondition(condition: .onQueue(internalQueue))
                        XCTAssertNil(error)
                        XCTAssertNotNil(serverTime)
                        XCTAssertEqual(serverTimeRequestCount, 1)
                        done()
                    }
                }
            }
        }
    }

    // MARK: - Connection details

    func test_connectionDetailsCallbackOnConnected() throws {
        // Given: A realtime client
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.plugins = [.liveObjects: MockLiveObjectsPlugin.self]
        options.autoConnect = false

        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        let channels = ["a", "b"].map { test.uniqueChannelName(prefix: $0) }.map { client.channels.get($0) }

        // When: The connection becomes CONNECTED

        client.connect()
        var transport: TestProxyTransport!
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                transport = client.internal.transport as? TestProxyTransport
                done()
            }
        }

        // Then: the connection details are passed to the plugin's onReceivedConnectionDetails, once for each channel, and they include the objectsGCGracePeriod
        var receivedConnectionDetails = MockLiveObjectsPlugin._internalPlugin.receivedConnectionDetails
        XCTAssertEqual(receivedConnectionDetails.count, channels.count)
        // Check we're correctly extracting it. In theory this can be nil, if this starts happening in sandbox then we'll need to test in some other way
        XCTAssertNotNil(receivedConnectionDetails[0].connectionDetails?.objectsGCGracePeriod)

        // When: another CONNECTED ProtocolMessage is received

        // Remove the existing received connection details from our mock
        MockLiveObjectsPlugin._internalPlugin.receivedConnectionDetails.removeAll()

        let connectedProtocolMessage = ARTProtocolMessage()
        connectedProtocolMessage.action = .connected
        let connectionDetails = ARTConnectionDetails(clientId: nil, connectionKey: nil, maxMessageSize: 100, maxFrameSize: 100, maxInboundRate: 100, connectionStateTtl: 100, serverId: "", maxIdleInterval: 100, objectsGCGracePeriod: 1500) // all arbitrary except objectsGCGracePeriod
        connectedProtocolMessage.connectionDetails = connectionDetails
        transport.receive(connectedProtocolMessage)

        // Then: the new connection details are passed to the plugin's onReceivedConnectionDetails, once for each channel, and they include the objectsGCGracePeriod
        receivedConnectionDetails = MockLiveObjectsPlugin._internalPlugin.receivedConnectionDetails
        XCTAssertEqual(receivedConnectionDetails.count, channels.count)
        XCTAssertEqual(receivedConnectionDetails[0].connectionDetails?.objectsGCGracePeriod, 1500)
    }

    func test_latestConnectionDetails() throws {
        // Given: A realtime client
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.autoConnect = false

        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        let pluginAPI = DependencyStore.sharedInstance().fetchPluginAPI()
        let pluginRealtimeClient = client.internal as! _AblyPluginSupportPrivate.RealtimeClient

        let internalQueue = client.internal.queue

        // When: The connection is not yet CONNECTED
        // Then: the plugin API latestConnectionDetails returns nil
        internalQueue.sync {
            XCTAssertNil(pluginAPI.nosync_latestConnectionDetails(for: pluginRealtimeClient))
        }

        // When: The connection becomes CONNECTED
        client.connect()
        var transport: TestProxyTransport!
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                transport = client.internal.transport as? TestProxyTransport
                done()
            }
        }

        // Then: the plugin API latestConnectionDetails returns the associated connection details
        internalQueue.sync {
            XCTAssertNotNil(pluginAPI.nosync_latestConnectionDetails(for: pluginRealtimeClient))
        }

        // When: another CONNECTED ProtocolMessage is received

        let connectedProtocolMessage = ARTProtocolMessage()
        connectedProtocolMessage.action = .connected
        let connectionDetails = ARTConnectionDetails(clientId: nil, connectionKey: nil, maxMessageSize: 100, maxFrameSize: 100, maxInboundRate: 100, connectionStateTtl: 100, serverId: "", maxIdleInterval: 100, objectsGCGracePeriod: 1500) // all arbitrary except objectsGCGracePeriod
        connectedProtocolMessage.connectionDetails = connectionDetails
        transport.receive(connectedProtocolMessage)

        // Then: the plugin API latestConnectionDetails returns the new associated connection details
        try internalQueue.sync {
            let newConnectionDetails = try XCTUnwrap(pluginAPI.nosync_latestConnectionDetails(for: pluginRealtimeClient))
            XCTAssertEqual(newConnectionDetails.objectsGCGracePeriod, 1500)
        }
    }

    // MARK: - Sending `ObjectMessage`

    func test_sendObjectMessage() throws {
        // Given: A realtime channel
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
//        options.autoConnect = false
        // TODO remove
        options.logLevel = .verbose

        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        let pluginAPI = DependencyStore.sharedInstance().fetchPluginAPI()
//        let pluginRealtimeClient = client.internal as! _AblyPluginSupportPrivate.RealtimeClient

        let channel = client.channels.get(test.uniqueChannelName())
        let pluginRealtimeChannel = channel.internal as! _AblyPluginSupportPrivate.RealtimeChannel

        let internalQueue = client.internal.queue

        // When: TODO

        client.close()
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.closed) { _ in
                done()
            }
        }
        XCTAssertEqual(channel.state, .detached)

        waitUntil(timeout: testTimeout) { done in
            internalQueue.sync {
                print("Sending object")
                // TODO what's the mechanism that's causing this to fail even though we've skipped a check?
                pluginAPI.nosync_sendObject(withObjectMessages: [], channel: pluginRealtimeChannel) { error in
                    XCTAssertNotNil(error)
                    done()
                }
            }
        }
    }
}
