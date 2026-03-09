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
        class MockObjectMessage: NSObject, _AblyPluginSupportPrivate.ObjectMessageProtocol {
            let identifier = UUID().uuidString
        }

        internal var receivedConnectionDetails: [(connectionDetails: (any ConnectionDetailsProtocol)?, channel: any RealtimeChannel)] = []
        internal var receivedChannelAttached: [(channel: any RealtimeChannel, hasObjects: Bool)] = []

        /// Resets all recorded mock state. Called in `setUp()` since this is a shared static instance.
        func clearState() {
            receivedConnectionDetails.removeAll()
            receivedChannelAttached.removeAll()
        }

        func nosync_prepare(_ channel: any RealtimeChannel, client: any RealtimeClient) {
            // no-op
        }

        func decodeObjectMessage(_ serialized: [String : Any], context: any DecodingContextProtocol, format: EncodingFormat, error: AutoreleasingUnsafeMutablePointer<(any PublicErrorInfo)?>?) -> (any ObjectMessageProtocol)? {
            return MockObjectMessage()
        }

        /// Encodes the object message's identifier under the key `mockMessageIdentifier`.
        func encodeObjectMessage(_ objectMessage: any ObjectMessageProtocol, format: EncodingFormat) -> [String : Any] {
            let mockMessage = objectMessage as! MockObjectMessage
            return ["mockMessageIdentifier": mockMessage.identifier]
        }

        func nosync_onChannelAttached(_ channel: any RealtimeChannel, hasObjects: Bool) {
            receivedChannelAttached.append((channel, hasObjects))
        }

        func nosync_handleObjectProtocolMessage(withObjectMessages objectMessages: [any ObjectMessageProtocol], channel: any RealtimeChannel) {
            // Method not currently tested
        }

        func nosync_handleObjectSyncProtocolMessage(withObjectMessages objectMessages: [any ObjectMessageProtocol], protocolMessageChannelSerial: String?, channel: any RealtimeChannel) {
            // Method not currently tested
        }

        func nosync_onConnected(withConnectionDetails connectionDetails: (any ConnectionDetailsProtocol)?, channel: any RealtimeChannel) {
            receivedConnectionDetails.append((connectionDetails, channel))
        }
    }

    static var liveObjectsChannelOptions: ARTRealtimeChannelOptions {
        let options = ARTRealtimeChannelOptions()
        options.modes = [.objectPublish, .objectSubscribe]
        return options
    }

    override func setUp() {
        super.setUp()
        MockLiveObjectsPlugin._internalPlugin.clearState()
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

    // MARK: - Channel attached

    func test_channelAttachedNotifiesPlugin() throws {
        // Given: A realtime client with a plugin
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.plugins = [.liveObjects: MockLiveObjectsPlugin.self]

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        let channelWithoutObjects = client.channels.get(test.uniqueChannelName(prefix: "no-objects"))
        let channelWithObjects = client.channels.get(test.uniqueChannelName(prefix: "objects"), options: Self.liveObjectsChannelOptions)

        // When: Both channels are attached
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            for channel in [channelWithoutObjects, channelWithObjects] {
                channel.attach { error in
                    XCTAssertNil(error)
                    partialDone()
                }
            }
        }

        // Then: The plugin is notified of both channel attaches, with the correct hasObjects flag
        let attached = MockLiveObjectsPlugin._internalPlugin.receivedChannelAttached
        XCTAssertEqual(attached.count, 2)

        let withoutObjects = try XCTUnwrap(attached.first { $0.channel === channelWithoutObjects.internal })
        XCTAssertFalse(withoutObjects.hasObjects)

        let withObjects = try XCTUnwrap(attached.first { $0.channel === channelWithObjects.internal })
        XCTAssertTrue(withObjects.hasObjects)
    }

    // MARK: - Send object

    func test_sendObject() throws {
        // Given: A realtime client with a plugin and an attached channel
        let test = Test()
        let options = try AblyTests.commonAppSetup(for: test)
        options.plugins = [.liveObjects: MockLiveObjectsPlugin.self]
        options.useBinaryProtocol = false
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(test.uniqueChannelName(), options: Self.liveObjectsChannelOptions)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
        }

        let transport = client.internal.transport as! TestProxyTransport
        let pluginAPI = DependencyStore.sharedInstance().fetchPluginAPI()
        let pluginChannel = channel.internal as! _AblyPluginSupportPrivate.RealtimeChannel
        let internalQueue = client.internal.queue

        // When: We call nosync_sendObject with a mock object message
        // (We don't wait for the completion handler; constructing a valid object message that
        // the server would ACK is out of scope for this test; we'll leave that for the LiveObjects
        // plugin tests)
        let mockObjectMessage = MockInternalLiveObjectsPlugin.MockObjectMessage()
        internalQueue.sync {
            pluginAPI.nosync_sendObject(withObjectMessages: [mockObjectMessage], channel: pluginChannel, completion: nil)
        }

        // Then: The SDK asks the mock plugin to encode the object message (which encodes
        // MockObjectMessage.identifier under the key "mockMessageIdentifier"), and sends the
        // result in an OBJECT protocol message
        let objectMessages = transport.protocolMessagesSent.filter { $0.action == .object }
        XCTAssertEqual(objectMessages.count, 1)

        let lastRawData = try XCTUnwrap(transport.rawDataSent.last)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: lastRawData) as? [String: Any])
        let state = try XCTUnwrap(json["state"] as? [[String: Any]])
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual(state[0]["mockMessageIdentifier"] as? String, mockObjectMessage.identifier)
    }
}
