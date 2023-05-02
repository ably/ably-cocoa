import Ably
import Nimble
import XCTest

func countChannels(_ channels: ARTRealtimeChannels) -> Int {
    var i = 0
    for _ in channels {
        i += 1
    }
    return i
}

private var ttlAndIdleIntervalPassedTestsClient: ARTRealtime!
private var ttlAndIdleIntervalPassedTestsConnectionId = ""
private let customTtlInterval: TimeInterval = 0.1
private let customIdleInterval: TimeInterval = 0.1
private var ttlAndIdleIntervalNotPassedTestsClient: ARTRealtime!
private var ttlAndIdleIntervalNotPassedTestsConnectionId = ""
private let expectedHostOrder = [3, 4, 0, 2, 1]
private let shuffleArrayInExpectedHostOrder = { (array: NSMutableArray) in
    let arranged = expectedHostOrder.reversed().map { array[$0] }
    for (i, element) in arranged.enumerated() {
        array[i] = element
    }
}
private func testUsesAlternativeHostOnResponse(_ caseTest: FakeNetworkResponse, channelName: String) {
    let options = ARTClientOptions(key: "xxxx:xxxx")
    options.autoConnect = false
    options.testOptions.realtimeRequestTimeout = 1.0
    let transportFactory = TestProxyTransportFactory()
    options.testOptions.transportFactory = transportFactory
    let client = ARTRealtime(options: options)
    defer { client.dispose(); client.close() }
    client.channels.get(channelName)

    transportFactory.fakeNetworkResponse = caseTest

    var urlConnections = [URL]()
    transportFactory.networkConnectEvent = { transport, url in
        if client.internal.transport !== transport {
            return
        }
        urlConnections.append(url)
        if urlConnections.count == 1 {
            transportFactory.fakeNetworkResponse = nil
        }
    }

    waitUntil(timeout: testTimeout) { done in
        // wss://[a-e].ably-realtime.com: when a timeout occurs
        client.connection.once(.disconnected) { _ in
            done()
        }
        // wss://[a-e].ably-realtime.com: when a 401 occurs because of the `xxxx:xxxx` key
        client.connection.once(.failed) { _ in
            done()
        }
        client.connect()
    }

    XCTAssertEqual(urlConnections.count, 2)
    XCTAssertTrue(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io"))
    XCTAssertTrue(NSRegularExpression.match(urlConnections[1].absoluteString, pattern: "//[a-e].ably-realtime.com"))
}

private func testMovesToDisconnectedWithNetworkingError(_ error: Error) throws {
    let options = try AblyTests.commonAppSetup()
    options.autoConnect = false
    options.testOptions.transportFactory = TestProxyTransportFactory()
    let client = AblyTests.newRealtime(options).client
    defer {
        client.dispose()
        client.close()
    }

    waitUntil(timeout: testTimeout) { done in
        client.connection.once(.connected) { _ in
            done()
        }
        client.connect()
    }

    var _transport: ARTWebSocketTransport?
    AblyTests.queue.sync {
        _transport = client.internal.transport as? ARTWebSocketTransport
    }

    guard let wsTransport = _transport else {
        fail("expected WS transport")
        return
    }

    waitUntil(timeout: testTimeout) { done in
        client.connection.once(.disconnected) { _ in
            done()
        }
        wsTransport.webSocket(wsTransport.websocket!, didFailWithError: error)
    }
}

private var internetConnectionNotAvailableTestsClient: ARTRealtime!
private let fixtures: [String: Any] = try! JSONUtility.jsonObject(
    data: try! Data(contentsOf: URL(fileURLWithPath: pathForTestResource(testResourcesPath + "messages-encoding.json")))
)!

private func expectDataToMatch(_ message: ARTMessage, _ fixtureMessage: Any) {
    let dictionaryValue = fixtureMessage as! [String: Any]
    
    switch dictionaryValue["expectedType"] as! String {
    case "string":
        XCTAssertEqual(message.data as? NSString, dictionaryValue["expectedValue"] as? NSString)
    case "jsonObject":
        if let data = message.data as? NSDictionary {
            XCTAssertEqual(data, dictionaryValue["expectedValue"] as? NSDictionary)
        } else {
            fail("expected NSDictionary")
        }
    case "jsonArray":
        if let data = message.data as? NSArray {
            XCTAssertEqual(data, dictionaryValue["expectedValue"] as? NSArray)
        } else {
            fail("expected NSArray")
        }
    case "binary":
        XCTAssertEqual(message.data as? NSData, (dictionaryValue["dictionaryValue"] as! String).dataFromHexadecimalString()! as NSData?)
    default:
        fail("unhandled: \(dictionaryValue["expectedType"] as! String)")
    }
}

private var jsonOptions: ARTClientOptions!
private var msgpackOptions: ARTClientOptions!

private func setupDependencies() throws {
    if jsonOptions == nil {
        jsonOptions = try AblyTests.commonAppSetup()
        jsonOptions.useBinaryProtocol = false
        // Keep the same key and channel prefix
        msgpackOptions = (jsonOptions.copy() as! ARTClientOptions)
        msgpackOptions.useBinaryProtocol = true
    }
}

class RealtimeClientConnectionTests: XCTestCase {
    // XCTest invokes this method before executing the first test in the test suite. We use it to ensure that the global variables are initialized at the same moment, and in the same order, as they would have been when we used the Quick testing framework.
    override class var defaultTestSuite: XCTestSuite {
        _ = ttlAndIdleIntervalPassedTestsClient
        _ = ttlAndIdleIntervalPassedTestsConnectionId
        _ = customTtlInterval
        _ = customIdleInterval
        _ = ttlAndIdleIntervalNotPassedTestsClient
        _ = ttlAndIdleIntervalNotPassedTestsConnectionId
        _ = expectedHostOrder
        _ = internetConnectionNotAvailableTestsClient
        _ = fixtures
        _ = jsonOptions
        _ = msgpackOptions

        return super.defaultTestSuite
    }

    // CD2c

    func test__016__Connection__ConnectionDetails__maxMessageSize_overrides_the_default_maxMessageSize() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        let defaultMaxMessageSize = ARTDefault.maxMessageSize()
        XCTAssertEqual(defaultMaxMessageSize, 65536)
        defer {
            ARTDefault.setMaxMessageSize(defaultMaxMessageSize)
            client.dispose()
            client.close()
        }
        ARTDefault.setMaxMessageSize(1)

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                let transport = client.internal.transport as! TestProxyTransport
                let firstConnectionDetails = transport.protocolMessagesReceived.filter { $0.action == .connected }[0].connectionDetails
                XCTAssertEqual(firstConnectionDetails!.maxMessageSize, 16384) // Sandbox apps have a 16384 limit
                done()
            }
            client.connect()
        }
    }

    // RTN2

    func test__017__Connection__url__should_connect_to_the_default_host() {
        let options = ARTClientOptions(key: "keytest:secret")
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        if let transport = client.internal.transport as? TestProxyTransport, let url = transport.lastUrl {
            XCTAssertEqual(url.host, "realtime.ably.io")
        } else {
            XCTFail("MockTransport isn't working")
        }
    }

    func test__018__Connection__url__should_connect_with_query_string_params() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                switch state {
                case .failed:
                    AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                    done()
                case .connected:
                    if let transport = client.internal.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                        expect(query).to(haveParam("key", withValue: options.key ?? ""))
                        expect(query).to(haveParam("echo", withValue: "true"))
                        expect(query).to(haveParam("format", withValue: "msgpack"))
                    } else {
                        XCTFail("MockTransport isn't working")
                    }
                    done()
                default:
                    break
                }
            }
        }
    }

    func test__019__Connection__url__should_connect_with_query_string_params_including_clientId() throws {
        let options = try AblyTests.commonAppSetup()
        options.clientId = "client_string"
        options.useTokenAuth = true
        options.autoConnect = false
        options.echoMessages = false
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                switch state {
                case .failed:
                    AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                    done()
                case .connected:
                    if let transport = client.internal.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                        expect(query).to(haveParam("accessToken", withValue: client.auth.tokenDetails?.token ?? ""))
                        expect(query).to(haveParam("echo", withValue: "false"))
                        expect(query).to(haveParam("format", withValue: "msgpack"))
                        expect(query).to(haveParam("clientId", withValue: "client_string"))
                    } else {
                        XCTFail("MockTransport isn't working")
                    }
                    done()
                default:
                    break
                }
            }
        }
    }

    // RTN3
    func test__001__Connection__should_connect_automatically() throws {
        let options = try AblyTests.commonAppSetup()
        var connected = false

        // Default
        XCTAssertTrue(options.autoConnect, "autoConnect should be true by default")

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        // The only way to control this functionality is with the options flag
        client.connection.on { stateChange in
            let state = stateChange.current
            let error = stateChange.reason
            XCTAssertNil(error)
            switch state {
            case .connected:
                connected = true
            default:
                break
            }
        }
        expect(connected).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), description: "Can't connect automatically")
    }

    func test__002__Connection__should_connect_manually() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        var waiting = true

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                switch state {
                case .connected:
                    if waiting {
                        XCTFail("Expected to be disconnected")
                    }
                    done()
                default:
                    break
                }
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
                waiting = false
                client.connect()
            }
        }
    }

    // RTN2f
    func test__003__Connection__API_version_param_must_be_included_in_all_connections() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connecting) { _ in
                guard let webSocketTransport = client.internal.transport as? ARTWebSocketTransport else {
                    fail("Transport should be of type ARTWebSocketTransport"); done()
                    return
                }
                XCTAssertNotNil(webSocketTransport.websocketURL)

                // This test should not directly validate version against ARTDefault.version(), as
                // ultimately the version header has been derived from that value.
                expect(webSocketTransport.websocketURL?.query).to(haveParam("v", withValue: "1.2"))

                done()
            }
            client.connect()
        }
    }

    // RTN2g (Deprecated in favor of RCS7d)

    // RSC7d
    func test__004__Connection__Library_and_version_param__agent__should_include_the__Ably_Agent__header_value() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        client.connect()

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                switch state {
                case .failed:
                    AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                    done()
                case .connected:
                    if let transport = client.internal.transport as? TestProxyTransport, let query = transport.lastUrl?.query {
                        expect(query).to(haveParam("agent", hasPrefix: "ably-cocoa/1.2.19"))
                    } else {
                        XCTFail("MockTransport isn't working")
                    }
                    done()
                default:
                    break
                }
            }
        }
        client.close()
    }

    // RTN4

    // RTN4a
    func test__020__Connection__event_emitter__should_emit_events_for_state_changes() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let connection = client.connection
        var events: [ARTRealtimeConnectionState] = []

        waitUntil(timeout: testTimeout) { done in
            var alreadyDisconnected = false
            var alreadyClosed = false

            connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                switch state {
                case .connecting:
                    if !alreadyDisconnected {
                        events += [state]
                    }
                case .connected:
                    if alreadyClosed {
                        delay(0) {
                            client.internal.onSuspended()
                        }
                    } else if alreadyDisconnected {
                        client.close()
                    } else {
                        events += [state]
                        delay(0) {
                            client.internal.onDisconnected()
                        }
                    }
                case .disconnected:
                    events += [state]
                    alreadyDisconnected = true
                case .suspended:
                    events += [state]
                    client.internal.onError(AblyTests.newErrorProtocolMessage())
                case .closing:
                    events += [state]
                case .closed:
                    events += [state]
                    alreadyClosed = true
                    client.connect()
                case .failed:
                    events += [state]
                    XCTAssertNotNil(errorInfo, "Error is nil")
                    connection.off()
                    done()
                default:
                    break
                }
            }
            events += [connection.state]
            connection.connect()
        }

        if events.count != 8 {
            fail("Missing some states, got \(events)")
            return
        }

        XCTAssertEqual(events[0].rawValue, ARTRealtimeConnectionState.initialized.rawValue, "Should be INITIALIZED state")
        XCTAssertEqual(events[1].rawValue, ARTRealtimeConnectionState.connecting.rawValue, "Should be CONNECTING state")
        XCTAssertEqual(events[2].rawValue, ARTRealtimeConnectionState.connected.rawValue, "Should be CONNECTED state")
        XCTAssertEqual(events[3].rawValue, ARTRealtimeConnectionState.disconnected.rawValue, "Should be DISCONNECTED state")
        XCTAssertEqual(events[4].rawValue, ARTRealtimeConnectionState.closing.rawValue, "Should be CLOSING state")
        XCTAssertEqual(events[5].rawValue, ARTRealtimeConnectionState.closed.rawValue, "Should be CLOSED state")
        XCTAssertEqual(events[6].rawValue, ARTRealtimeConnectionState.suspended.rawValue, "Should be SUSPENDED state")
        XCTAssertEqual(events[7].rawValue, ARTRealtimeConnectionState.failed.rawValue, "Should be FAILED state")
    }

    // RTN4h
    func test__021__Connection__event_emitter__should_never_emit_a_ConnectionState_event_for_a_state_equal_to_the_previous_state() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
        }

        client.connection.once(.connected) { _ in
            fail("Should not emit a Connected state")
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.update) { stateChange in
                XCTAssertNil(stateChange.reason)
                XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.current, stateChange.previous)
                done()
            }

            let authMessage = ARTProtocolMessage()
            authMessage.action = .auth
            client.internal.transport?.receive(authMessage)
        }
    }

    // RTN4b
    func test__022__Connection__event_emitter__should_emit_states_on_a_new_connection() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let connection = client.connection
        var events: [ARTRealtimeConnectionState] = []

        waitUntil(timeout: testTimeout) { done in
            connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                switch state {
                case .connecting:
                    events += [state]
                case .connected:
                    events += [state]
                    done()
                default:
                    break
                }
            }
            connection.connect()
        }

        expect(events).to(haveCount(2), description: "Missing CONNECTING or CONNECTED state")

        if events.count != 2 {
            return
        }

        XCTAssertEqual(events[0].rawValue, ARTRealtimeConnectionState.connecting.rawValue, "Should be CONNECTING state")
        XCTAssertEqual(events[1].rawValue, ARTRealtimeConnectionState.connected.rawValue, "Should be CONNECTED state")
    }

    // RTN4c
    func test__023__Connection__event_emitter__should_emit_states_when_connection_is_closed() throws {
        let client = ARTRealtime(options: try AblyTests.commonAppSetup())
        let connection = client.connection
        defer { client.dispose(); client.close() }
        var events: [ARTRealtimeConnectionState] = []

        waitUntil(timeout: testTimeout) { done in
            connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                switch state {
                case .connected:
                    connection.close()
                case .closing:
                    events += [state]
                case .closed:
                    events += [state]
                    done()
                default:
                    break
                }
            }
        }

        expect(events).to(haveCount(2), description: "Missing CLOSING or CLOSED state")

        if events.count != 2 {
            return
        }

        XCTAssertEqual(events[0].rawValue, ARTRealtimeConnectionState.closing.rawValue, "Should be CLOSING state")
        XCTAssertEqual(events[1].rawValue, ARTRealtimeConnectionState.closed.rawValue, "Should be CLOSED state")
    }

    // RTN4d
    func test__024__Connection__event_emitter__should_have_the_current_state() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let connection = client.connection
        XCTAssertEqual(connection.state.rawValue, ARTRealtimeConnectionState.initialized.rawValue, "Missing INITIALIZED state")

        waitUntil(timeout: testTimeout) { done in
            connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                switch state {
                case .connecting:
                    XCTAssertEqual(connection.state.rawValue, ARTRealtimeConnectionState.connecting.rawValue, "Missing CONNECTING state")
                case .connected:
                    XCTAssertEqual(connection.state.rawValue, ARTRealtimeConnectionState.connected.rawValue, "Missing CONNECTED state")
                    done()
                default:
                    break
                }
            }
            client.connect()
        }
    }

    // RTN4e
    func test__025__Connection__event_emitter__should_have_a_ConnectionStateChange_as_first_argument_for_every_connection_state_change() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(ARTRealtimeConnectionEvent.connected) { stateChange in
                expect(stateChange).to(beAKindOf(ARTConnectionStateChange.self))
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.connecting)
                done()
            }
            client.connect()
        }
    }

    // RTN4f
    func test__026__Connection__event_emitter__should_have_the_reason_which_contains_an_ErrorInfo() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let connection = client.connection

        var errorInfo: ARTErrorInfo?
        waitUntil(timeout: testTimeout) { done in
            connection.on { stateChange in
                let state = stateChange.current
                let reason = stateChange.reason
                switch state {
                case .connected:
                    XCTAssertEqual(stateChange.event, ARTRealtimeConnectionEvent.connected)
                    client.internal.onError(AblyTests.newErrorProtocolMessage())
                case .failed:
                    XCTAssertEqual(stateChange.event, ARTRealtimeConnectionEvent.failed)
                    errorInfo = reason
                    done()
                default:
                    break
                }
            }
        }

        XCTAssertNotNil(errorInfo)
    }

    // RTN4f
    func test__027__Connection__event_emitter__any_state_change_triggered_by_a_ProtocolMessage_that_contains_an_Error_member_should_populate_the_Reason_property() throws {
        let options = try AblyTests.commonAppSetup()
        options.useTokenAuth = true
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
        }

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }
        guard let originalConnectedMessage = transport.protocolMessagesReceived.filter({ $0.action == .connected }).first else {
            fail("First CONNECTED message not received"); return
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.update) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Reason error is nil"); done(); return
                }
                XCTAssertEqual(error.code, 1234)
                XCTAssertEqual(error.message, "fabricated error")
                XCTAssertEqual(stateChange.event, ARTRealtimeConnectionEvent.update)
                done()
            }

            let connectedMessageWithError = originalConnectedMessage
            connectedMessageWithError.error = ARTErrorInfo.create(withCode: 1234, message: "fabricated error")
            client.internal.transport?.receive(connectedMessageWithError)
        }
    }

    // RTN5
    func test__005__Connection__basic_operations_should_work_simultaneously() throws {
        let options = try AblyTests.commonAppSetup()
        options.echoMessages = false
        var disposable = [ARTRealtime]()
        let numClients = 50
        let numMessages = 5
        let channelName = "chat"
        let testTimeout = DispatchTimeInterval.seconds(60)

        defer {
            for client in disposable {
                client.dispose()
                client.close()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(numClients, done: done)
            for _ in 1 ... numClients {
                let client = ARTRealtime(options: options)
                disposable.append(client)
                let channel = client.channels.get(channelName)
                channel.attach { error in
                    if let error = error {
                        fail(error.message); done()
                    }
                    partialDone()
                }
            }
        }

        var messagesReceived = 0
        waitUntil(timeout: testTimeout) { done in
            // Sends numMessages messages from different clients to the same channel
            // numMessages messages for numClients clients = numMessages*numClients total messages
            // echo is off, so we need to subtract one message per publish
            let messagesExpected = numMessages * numClients - 1 * numMessages
            var messagesSent = 0
            for client in disposable {
                let channel = client.channels.get(channelName)
                XCTAssertEqual(channel.state, ARTRealtimeChannelState.attached)

                channel.subscribe { message in
                    XCTAssertEqual(message.data as? String, "message_string")
                    messagesReceived += 1
                    if messagesReceived == messagesExpected {
                        done()
                    }
                }

                if messagesSent < numMessages {
                    channel.publish(nil, data: "message_string", callback: nil)
                    messagesSent += 1
                }
            }
        }

        XCTAssertEqual(disposable.count, numClients)
        XCTAssertEqual(countChannels(disposable.first!.channels), 1)
        XCTAssertEqual(countChannels(disposable.last!.channels), 1)
    }

    // RTN6
    func test__006__Connection__should_have_an_opened_websocket_connection_and_received_a_CONNECTED_ProtocolMessage() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer {
            client.dispose()
            client.close()
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                if state == .connected, error == nil {
                    done()
                }
            }
        }

        if let webSocketTransport = client.internal.transport as? ARTWebSocketTransport {
            XCTAssertEqual(webSocketTransport.state, ARTRealtimeTransportState.opened)
        } else {
            XCTFail("WebSocket is not the default transport")
        }

        if let transport = client.internal.transport as? TestProxyTransport {
            // CONNECTED ProtocolMessage
            expect(transport.protocolMessagesReceived.map { $0.action }).to(contain(ARTProtocolMessageAction.connected))
        } else {
            XCTFail("MockTransport is not working")
        }
    }

    // RTN7

    // RTN7a

    func test__028__Connection__ACK_and_NACK__should_expect_either_an_ACK_or_NACK_to_confirm__successful_receipt_and_acceptance_of_message() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.clientId = "client_string"
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            publishFirstTestMessage(client, channelName: uniqueChannelName(), completion: { error in
                XCTAssertNil(error)
                done()
            })
        }

        let transport = client.internal.transport as! TestProxyTransport

        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .message }).last else {
            XCTFail("No MESSAGE action was sent"); return
        }

        guard let receivedAck = transport.protocolMessagesReceived.filter({ $0.action == .ack }).last else {
            XCTFail("No ACK action was received"); return
        }

        XCTAssertEqual(publishedMessage.msgSerial, receivedAck.msgSerial)
    }

    func test__029__Connection__ACK_and_NACK__should_expect_either_an_ACK_or_NACK_to_confirm__successful_receipt_and_acceptance_of_presence() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.clientId = "client_string"
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                if state == .connected {
                    let channel = client.channels.get(uniqueChannelName())
                    channel.attach { error in
                        XCTAssertNil(error)
                        channel.presence.enterClient("client_string", data: nil, callback: { errorInfo in
                            XCTAssertNil(errorInfo)
                            done()
                        })
                    }
                }
            }
        }

        let transport = client.internal.transport as! TestProxyTransport

        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .presence }).last else {
            XCTFail("No PRESENCE action was sent"); return
        }

        guard let receivedAck = transport.protocolMessagesReceived.filter({ $0.action == .ack }).last else {
            XCTFail("No ACK action was received"); return
        }

        XCTAssertEqual(publishedMessage.msgSerial, receivedAck.msgSerial)
    }

    func test__030__Connection__ACK_and_NACK__should_expect_either_an_ACK_or_NACK_to_confirm__message_failure() throws {
        let options = try AblyTests.commonAppSetup()
        
        let channelName = uniqueChannelName()
        options.token = try getTestToken(key: options.key, capability: "{ \"\(options.testOptions.channelNamePrefix!)-\(channelName)\":[\"subscribe\"] }")
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            publishFirstTestMessage(client, channelName: channelName, completion: { error in
                XCTAssertNotNil(error)
                done()
            })
        }

        let transport = client.internal.transport as! TestProxyTransport

        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .message }).last else {
            XCTFail("No MESSAGE action was sent"); return
        }

        guard let receivedNack = transport.protocolMessagesReceived.filter({ $0.action == .nack }).last else {
            XCTFail("No NACK action was received"); return
        }

        XCTAssertEqual(publishedMessage.msgSerial, receivedNack.msgSerial)
    }

    func test__031__Connection__ACK_and_NACK__should_expect_either_an_ACK_or_NACK_to_confirm__presence_failure() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.clientId = "client_string"
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                if state == .connected {
                    let channel = client.channels.get(uniqueChannelName())
                    channel.attach { error in
                        XCTAssertNil(error)
                        channel.presence.enterClient("invalid", data: nil, callback: { errorInfo in
                            XCTAssertNotNil(errorInfo)
                            done()
                        })
                    }
                }
            }
        }

        let transport = client.internal.transport as! TestProxyTransport

        guard let publishedMessage = transport.protocolMessagesSent.filter({ $0.action == .presence }).last else {
            XCTFail("No PRESENCE action was sent"); return
        }

        guard let receivedNack = transport.protocolMessagesReceived.filter({ $0.action == .nack }).last else {
            XCTFail("No NACK action was received"); return
        }

        XCTAssertEqual(publishedMessage.msgSerial, receivedNack.msgSerial)
    }

    // RTN7b

    func test__032__Connection__ACK_and_NACK__ProtocolMessage__should_contain_unique_serially_incrementing_msgSerial_along_with_the_count() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.clientId = "client_string"
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(uniqueChannelName())
        channel.attach()

        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: "message") { errorInfo in
                XCTAssertNil(errorInfo)
                done()
            }
        }

        struct TotalMessages {
            static let expected = 5
            var succeeded = 0
        }

        var totalMessages = TotalMessages()

        for index in 1 ... TotalMessages.expected {
            channel.publish(nil, data: "message\(index)") { errorInfo in
                if errorInfo == nil {
                    totalMessages.succeeded += 1
                }
            }
        }
        expect(totalMessages.succeeded).toEventually(equal(TotalMessages.expected), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            channel.presence.enterClient("invalid", data: nil, callback: { errorInfo in
                XCTAssertNotNil(errorInfo)
                done()
            })
        }

        let transport = client.internal.transport as! TestProxyTransport
        let acks = transport.protocolMessagesReceived.filter { $0.action == .ack }
        let nacks = transport.protocolMessagesReceived.filter { $0.action == .nack }

        if acks.count != 2 {
            fail("Received invalid number of ACK responses: \(acks.count)")
            return
        }

        XCTAssertEqual(acks[0].msgSerial, 0)
        XCTAssertEqual(acks[0].count, 1)

        // Messages covered in a single ACK response
        XCTAssertEqual(acks[1].msgSerial, 1)
        XCTAssertEqual(Int(acks[1].count), TotalMessages.expected)

        if nacks.count != 1 {
            fail("Received invalid number of NACK responses: \(nacks.count)")
            return
        }

        XCTAssertEqual(nacks[0].msgSerial, 6)
        XCTAssertEqual(nacks[0].count, 1)
    }

    func test__033__Connection__ACK_and_NACK__ProtocolMessage__should_continue_incrementing_msgSerial_serially_if_the_connection_resumes_successfully() throws {
        let options = try AblyTests.commonAppSetup()
        options.clientId = "tester"
        options.tokenDetails = try getTestTokenDetails(key: options.key!, clientId: options.clientId, ttl: 5.0)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: "message") { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let initialConnectionId = client.connection.id else {
            fail("Connection ID is empty"); return
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            (1 ... 3).forEach { index in
                channel.publish(nil, data: "message\(index)") { error in
                    if error == nil {
                        partialDone()
                    }
                }
            }
            channel.presence.enterClient("invalid", data: nil) { error in
                XCTAssertNotNil(error)
                partialDone()
            }
        }

        XCTAssertEqual(client.internal.msgSerial, 5)

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.disconnected) { stateChange in
                XCTAssertNotNil(stateChange.reason)
                // Token expired
                done()
            }
        }

        // Reconnected and resumed
        XCTAssertEqual(client.connection.id, initialConnectionId)
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            (1 ... 3).forEach { index in
                channel.publish(nil, data: "message\(index)") { error in
                    if error == nil {
                        partialDone()
                    }
                }
            }
            channel.presence.enterClient("invalid", data: nil) { error in
                XCTAssertNotNil(error)
                partialDone()
            }
        }

        guard let reconnectedTransport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }
        let acks = reconnectedTransport.protocolMessagesReceived.filter { $0.action == .ack }
        let nacks = reconnectedTransport.protocolMessagesReceived.filter { $0.action == .nack }

        if acks.count != 1 {
            fail("Received invalid number of ACK responses: \(acks.count)")
            return
        }
        // Messages covered in a single ACK response
        XCTAssertEqual(acks[0].msgSerial, 5) // [0] 1st publish + [1.2.4] publish + [4] enter with invalid client + [5] queued messages
        XCTAssertEqual(acks[0].count, 1)

        if nacks.count != 1 {
            fail("Received invalid number of NACK responses: \(nacks.count)")
            return
        }
        XCTAssertEqual(nacks[0].msgSerial, 6)
        XCTAssertEqual(nacks[0].count, 1)

        XCTAssertEqual(client.internal.msgSerial, 7)
    }

    func test__034__Connection__ACK_and_NACK__ProtocolMessage__should_reset_msgSerial_serially_if_the_connection_does_not_resume() throws {
        let options = try AblyTests.commonAppSetup()
        options.clientId = "tester"
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: "message") { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let initialConnectionId = client.connection.id else {
            fail("Connection ID is empty"); return
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            (1 ... 3).forEach { index in
                channel.publish(nil, data: "message\(index)") { error in
                    if error == nil {
                        partialDone()
                    }
                }
            }
            channel.presence.enterClient("invalid", data: nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.invalidClientId.intValue)
                partialDone()
            }
        }

        XCTAssertEqual(client.internal.msgSerial, 5)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            client.connection.once(.disconnected) { _ in
                partialDone()
            }
            client.connection.once(.connected) { _ in
                partialDone()
            }
            client.simulateLostConnectionAndState()
        }

        // Reconnected but not resumed
        XCTAssertNotEqual(client.connection.id, initialConnectionId)
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(4, done: done)
            (1 ... 3).forEach { index in
                channel.publish(nil, data: "message\(index)") { error in
                    if error == nil {
                        partialDone()
                    }
                }
            }
            channel.presence.enterClient("invalid", data: nil) { error in
                XCTAssertEqual(error?.code, ARTErrorCode.invalidClientId.intValue)
                partialDone()
            }
        }

        guard let reconnectedTransport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }
        let acks = reconnectedTransport.protocolMessagesReceived.filter { $0.action == .ack }
        let nacks = reconnectedTransport.protocolMessagesReceived.filter { $0.action == .nack }

        // The server is free to roll up multiple acks into one or not
        if acks.count < 1 {
            fail("Received invalid number of ACK responses: \(acks.count)")
            return
        }
        XCTAssertEqual(acks[0].msgSerial, 0)
        XCTAssertEqual(acks.reduce(0) { $0 + $1.count }, 3)

        if nacks.count != 1 {
            fail("Received invalid number of NACK responses: \(nacks.count)")
            return
        }
        XCTAssertEqual(nacks[0].msgSerial, 3)
        XCTAssertEqual(nacks[0].count, 1)

        XCTAssertEqual(client.internal.msgSerial, 4)
    }

    // RTN7c

    func test__035__Connection__ACK_and_NACK__should_trigger_the_failure_callback_for_the_remaining_pending_messages_if__connection_is_closed() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.clientId = "client_string"
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(uniqueChannelName())
        let transport = client.internal.transport as! TestProxyTransport
        transport.actionsIgnored += [.ack, .nack]

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                channel.publish(nil, data: "message", callback: { error in
                    guard let error = error else {
                        fail("Error is nil"); done(); return
                    }
                    expect(error.message).to(contain("connection broken before receiving publishing acknowledgment"))
                    done()
                })
                // Wait until the message is pushed to Ably first
                delay(1.0) {
                    client.close()
                }
            }
        }

        // This verifies that the pending message as been released and the publish callback is called only once!
        waitUntil(timeout: testTimeout) { done in
            delay(1.0) {
                done()
            }
        }
    }

    func test__036__Connection__ACK_and_NACK__should_trigger_the_failure_callback_for_the_remaining_pending_messages_if__connection_state_enters_FAILED() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.clientId = "client_string"
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }

        let channel = client.channels.get(uniqueChannelName())
        let transport = client.internal.transport as! TestProxyTransport
        transport.actionsIgnored += [.ack, .nack]

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                channel.publish(nil, data: "message", callback: { errorInfo in
                    XCTAssertNotNil(errorInfo)
                    done()
                })
                // Wait until the message is pushed to Ably first
                delay(1.0) {
                    transport.simulateIncomingError()
                }
            }
        }
    }

    func test__037__Connection__ACK_and_NACK__should_trigger_the_failure_callback_for_the_remaining_pending_messages_if__lost_connection_state() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer {
            client.dispose()
            client.close()
        }

        let channel = client.channels.get(uniqueChannelName())

        let transport = client.internal.transport as! TestProxyTransport
        transport.actionsIgnored += [.ack, .nack]

        waitUntil(timeout: testTimeout) { done in
            channel.attach { _ in
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)

            channel.publish(nil, data: "message") { error in
                guard let error = error else {
                    fail("Error is nil"); return
                }
                XCTAssertEqual(error.code, ARTErrorCode.unableToRecoverConnectionExpired.intValue)
                expect(error.message).to(contain("Unable to recover connection"))
                partialDone()
            }

            let oldConnectionId = client.connection.id!

            // Wait until the message is pushed to Ably first
            delay(1.0) {
                client.connection.once(.disconnected) { _ in
                    partialDone()
                }
                client.connection.once(.connected) { _ in
                    XCTAssertNotEqual(client.connection.id, oldConnectionId)
                    partialDone()
                }
                client.simulateLostConnectionAndState()
            }
        }
    }

    // RTN8

    // RTN8a
    func test__038__Connection__connection_id__should_be_null_until_connected() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        let connection = client.connection
        defer {
            client.dispose()
            client.close()
        }

        XCTAssertNil(connection.id)

        waitUntil(timeout: testTimeout) { done in
            connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                XCTAssertNil(errorInfo)
                if state == .connected {
                    XCTAssertNotNil(connection.id)
                    done()
                } else if state == .connecting {
                    XCTAssertNil(connection.id)
                }
            }
        }
    }

    // RTN8b
    func test__039__Connection__connection_id__should_have_unique_IDs() throws {
        let options = try AblyTests.commonAppSetup()
        var disposable = [ARTRealtime]()
        defer {
            for client in disposable {
                client.dispose()
                client.close()
            }
        }
        var ids = [String]()
        let max = 25
        let sync = NSLock()

        waitUntil(timeout: testTimeout) { done in
            for _ in 1 ... max {
                disposable.append(ARTRealtime(options: options))
                let currentConnection = disposable.last!.connection
                currentConnection.on { stateChange in
                    let state = stateChange.current
                    let error = stateChange.reason
                    XCTAssertNil(error)
                    if state == .connected {
                        guard let connectionId = currentConnection.id else {
                            fail("connectionId is nil on CONNECTED")
                            done()
                            return
                        }
                        expect(ids).toNot(contain(connectionId))

                        sync.lock()
                        ids.append(connectionId)
                        if ids.count == max {
                            done()
                        }
                        sync.unlock()

                        currentConnection.off()
                        currentConnection.close()
                    }
                }
            }
        }

        XCTAssertEqual(ids.count, max)
    }

    // RTN9

    // RTN9a
    func test__040__Connection__connection_key__should_be_null_until_connected() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }
        let connection = client.connection

        XCTAssertNil(connection.key)

        waitUntil(timeout: testTimeout) { done in
            connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                XCTAssertNil(errorInfo)
                if state == .connected {
                    XCTAssertNotNil(connection.id)
                    done()
                } else if state == .connecting {
                    XCTAssertNil(connection.key)
                }
            }
        }
    }

    // RTN9b
    func test__041__Connection__connection_key__should_have_unique_connection_keys() throws {
        let options = try AblyTests.commonAppSetup()
        var disposable = [ARTRealtime]()
        defer {
            for client in disposable {
                client.dispose()
                client.close()
            }
        }
        var keys = [String]()
        let max = 25

        waitUntil(timeout: testTimeout) { done in
            for _ in 1 ... max {
                disposable.append(ARTRealtime(options: options))
                let currentConnection = disposable.last!.connection
                currentConnection.on { stateChange in
                    let state = stateChange.current
                    let error = stateChange.reason
                    XCTAssertNil(error)
                    if state == .connected {
                        guard let connectionKey = currentConnection.key else {
                            fail("connectionKey is nil on CONNECTED")
                            done()
                            return
                        }
                        expect(keys).toNot(contain(connectionKey))
                        keys.append(connectionKey)

                        if keys.count == max {
                            done()
                        }

                        currentConnection.off()
                        currentConnection.close()
                    }
                }
            }
        }

        XCTAssertEqual(keys.count, max)
    }

    // RTN10

    // RTN10a
    func test__042__Connection__serial__should_be_minus_1_once_connected() throws {
        let client = ARTRealtime(options: try AblyTests.commonAppSetup())
        defer {
            client.dispose()
            client.close()
        }
        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                if state == .connected {
                    XCTAssertEqual(client.connection.serial, -1)
                    done()
                }
            }
        }
    }

    // RTN10b
    func test__043__Connection__serial__should_not_update_when_a_message_is_sent_but_increments_by_one_when_ACK_is_received() throws {
        let client = ARTRealtime(options: try AblyTests.commonAppSetup())
        defer {
            client.dispose()
            client.close()
        }
        let channel = client.channels.get(uniqueChannelName())

        XCTAssertEqual(client.connection.serial, -1)
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        XCTAssertEqual(client.connection.serial, -1)

        for index in 0 ... 3 {
            waitUntil(timeout: testTimeout) { done in
                let partialDone = AblyTests.splitDone(2, done: done)
                channel.publish(nil, data: "message", callback: { errorInfo in
                    XCTAssertNil(errorInfo)
                    partialDone()
                })
                channel.subscribe { _ in
                    // Updated
                    XCTAssertEqual(client.connection.serial, Int64(index))
                    channel.unsubscribe()
                    partialDone()
                }
                // Not updated
                XCTAssertEqual(client.connection.serial, Int64(index - 1))
            }
        }
    }

    func test__044__Connection__serial__should_have_last_known_connection_serial_from_restored_connection() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }
        let channelName = uniqueChannelName()
        let channel = client.channels.get(channelName)

        // Attach first to avoid bundling publishes in the same ProtocolMessage.
        channel.attach()
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        for _ in 1 ... 5 {
            waitUntil(timeout: testTimeout) { done in
                let partialDone = AblyTests.splitDone(2, done: done)
                channel.publish(nil, data: "message", callback: { errorInfo in
                    XCTAssertNil(errorInfo)
                    partialDone()
                })
                channel.subscribe { _ in
                    channel.unsubscribe()
                    partialDone()
                }
            }
        }
        let lastSerial = client.connection.serial
        XCTAssertEqual(lastSerial, 4)

        options.recover = client.connection.recoveryKey
        client.internal.onError(AblyTests.newErrorProtocolMessage())

        let recoveredClient = ARTRealtime(options: options)
        defer { recoveredClient.close() }
        expect(recoveredClient.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            XCTAssertEqual(recoveredClient.connection.serial, lastSerial)
            let recoveredChannel = recoveredClient.channels.get(channelName)
            recoveredChannel.publish(nil, data: "message", callback: { errorInfo in
                XCTAssertNil(errorInfo)
            })
            recoveredChannel.subscribe { _ in
                XCTAssertEqual(recoveredClient.connection.serial, lastSerial + 1)
                recoveredChannel.unsubscribe()
                done()
            }
        }
    }

    // RTN11b
    func test__007__Connection__should_make_a_new_connection_with_a_new_transport_instance_if_the_state_is_CLOSING() throws {
        let client = ARTRealtime(options: try AblyTests.commonAppSetup())
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                done()
            }
        }

        weak var oldTransport: ARTRealtimeTransport?
        weak var newTransport: ARTRealtimeTransport?

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)

            client.connection.once(.closing) { _ in
                oldTransport = client.internal.transport
                client.connect()
                newTransport = client.internal.transport
                expect(newTransport).toNot(beIdenticalTo(oldTransport))
                partialDone()
            }

            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                XCTAssertNil(client.connection.errorReason)
                partialDone()
            }

            client.close()
        }

        XCTAssertNotNil(newTransport)
    }

    // RTN11b
    func test__008__Connection__it_should_make_sure_that__when_the_CLOSED_ProtocolMessage_arrives_for_the_old_connection__it_doesn_t_affect_the_new_one() throws {
        let client = AblyTests.newRealtime(try AblyTests.commonAppSetup()).client
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                done()
            }
        }

        var oldTransport: ARTRealtimeTransport? // retain
        weak var newTransport: ARTRealtimeTransport?

        autoreleasepool {
            waitUntil(timeout: testTimeout) { done in
                let partialDone = AblyTests.splitDone(3, done: done)

                client.connection.once(.closing) { _ in
                    client.internalSync { _internal in
                        oldTransport = _internal.transport
                    }
                    // Old connection must complete the close request
                    weak var oldTestProxyTransport = oldTransport as? TestProxyTransport
                    oldTestProxyTransport?.setBeforeIncomingMessageModifier { protocolMessage in
                        if protocolMessage.action == .closed {
                            partialDone()
                        }
                        return protocolMessage
                    }

                    client.connect()

                    client.internalSync { _internal in
                        newTransport = _internal.transport
                    }

                    expect(newTransport).toNot(beIdenticalTo(oldTransport))
                    XCTAssertNotNil(newTransport)
                    XCTAssertNotNil(oldTransport)
                    partialDone()
                }

                client.connection.once(.closed) { _ in
                    fail("New connection should not receive the old connection event")
                }

                client.connection.once(.connected) { _ in
                    partialDone()
                }

                client.close()
            }

            oldTransport = nil
        }

        XCTAssertNotNil(newTransport)
        XCTAssertNil(oldTransport)
    }

    // RTN12

    // RTN12f
    func test__045__Connection__close__if_CONNECTING__do_the_operation_once_CONNECTED() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let client = ARTRealtime(options: options)
        defer { client.dispose() }

        client.connect()
        var lastStateChange: ARTConnectionStateChange?
        client.connection.on { stateChange in
            lastStateChange = stateChange
        }

        client.close()
        XCTAssertNil(lastStateChange)

        expect(lastStateChange).toEventuallyNot(beNil(), timeout: testTimeout)
        expect(lastStateChange!.current).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)
    }

    // RTN12a
    func test__046__Connection__close__if_CONNECTED__should_send_a_CLOSE_action__change_state_to_CLOSING_and_receive_a_CLOSED_action() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer {
            client.dispose()
        }

        let transport = client.internal.transport as! TestProxyTransport
        var states: [ARTRealtimeConnectionState] = []

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                switch state {
                case .connected:
                    client.close()
                case .closing:
                    XCTAssertEqual(transport.protocolMessagesSent.filter { $0.action == .close }.count, 1)
                    states += [state]
                case .closed:
                    XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .closed }.count, 1)
                    states += [state]
                    done()
                default:
                    break
                }
            }
        }

        if states.count != 2 {
            fail("Invalid number of connection states. Expected CLOSING and CLOSE states")
            return
        }
        XCTAssertEqual(states[0], ARTRealtimeConnectionState.closing)
        XCTAssertEqual(states[1], ARTRealtimeConnectionState.closed)
    }

    // RTN12b
    func test__047__Connection__close__should_transition_to_CLOSED_action_when_the_close_process_timeouts() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer {
            client.dispose()
            client.close()
        }

        let transport = client.internal.transport as! TestProxyTransport
        transport.actionsIgnored += [.closed]

        var states: [ARTRealtimeConnectionState] = []
        var start: NSDate?
        var end: NSDate?

        client.connection.on { stateChange in
            let state = stateChange.current
            let error = stateChange.reason
            XCTAssertNil(error)
            switch state {
            case .connected:
                client.close()
            case .closing:
                start = NSDate()
                states += [state]
            case .closed:
                end = NSDate()
                states += [state]
            case .disconnected:
                states += [state]
            default:
                break
            }
        }

        expect(start).toEventuallyNot(beNil(), timeout: testTimeout)
        expect(end).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.milliseconds(Int(1000.0 * ARTDefault.realtimeRequestTimeout())))

        if states.count != 2 {
            fail("Invalid number of connection states. Expected CLOSING and CLOSE states")
            return
        }

        XCTAssertEqual(states[0], ARTRealtimeConnectionState.closing)
        XCTAssertEqual(states[1], ARTRealtimeConnectionState.closed)
    }

    // RTN12c
    func test__048__Connection__close__transitions_to_the_CLOSING_state_and_then_to_the_CLOSED_state_if_the_transport_is_abruptly_closed() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        client.connect()
        defer {
            client.dispose()
            client.close()
        }

        let transport = client.internal.transport as! TestProxyTransport
        var states: [ARTRealtimeConnectionState] = []

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let error = stateChange.reason
                XCTAssertNil(error)
                switch state {
                case .connected:
                    states += [state]
                    client.close()
                case .closing:
                    states += [state]
                    transport.simulateIncomingAbruptlyClose()
                case .closed:
                    states += [state]
                    done()
                case .disconnected, .suspended, .failed:
                    states += [state]
                default:
                    break
                }
            }
        }

        if states.count != 3 {
            fail("Invalid number of connection states. Expected CONNECTED, CLOSING and CLOSE states (got \(states.map { $0.rawValue }))")
            return
        }

        XCTAssertEqual(states[0], ARTRealtimeConnectionState.connected)
        XCTAssertEqual(states[1], ARTRealtimeConnectionState.closing)
        XCTAssertEqual(states[2], ARTRealtimeConnectionState.closed)
    }

    // RTN12d
    func test__049__Connection__close__if_DISCONNECTED__aborts_the_retry_and_moves_immediately_to_CLOSED() throws {
        let options = try AblyTests.commonAppSetup()
        options.disconnectedRetryTimeout = 1.0
        let client = ARTRealtime(options: options)
        defer {
            client.close()
            client.dispose()
        }

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        client.internal.onDisconnected()
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.disconnected), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            client.connection.once { stateChange in
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.closed)
                partialDone()
            }

            client.close()

            delay(options.disconnectedRetryTimeout + 0.5) {
                // Make sure the retry doesn't happen.
                XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.closed)
                partialDone()
            }
        }
    }

    // RTN12e
    func test__050__Connection__close__if_SUSPENDED__aborts_the_retry_and_moves_immediately_to_CLOSED() throws {
        let options = try AblyTests.commonAppSetup()
        options.suspendedRetryTimeout = 1.0
        let client = ARTRealtime(options: options)
        defer {
            client.close()
            client.dispose()
        }

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        client.internal.onSuspended()
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.suspended), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            client.connection.once { stateChange in
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.closed)
                partialDone()
            }

            client.close()

            delay(options.suspendedRetryTimeout + 0.5) {
                // Make sure the retry doesn't happen.
                XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.closed)
                partialDone()
            }
        }
    }

    // RTN13

    // RTN13b
    func test__051__Connection__ping__fails_if_in_the_INITIALIZED__SUSPENDED__CLOSING__CLOSED_or_FAILED_state() throws {
        let options = try AblyTests.commonAppSetup()
        options.suspendedRetryTimeout = 0.1
        options.autoConnect = false
        let client = ARTRealtime(options: options)
        defer {
            client.close()
            client.dispose()
        }

        var error: ARTErrorInfo?
        func ping() {
            error = nil
            waitUntil(timeout: testTimeout) { done in
                client.ping { e in
                    error = e
                    done()
                }
            }
        }

        XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.initialized)
        ping()
        XCTAssertNotNil(error)

        client.connect()
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        client.internal.onSuspended()

        XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.suspended)
        ping()
        XCTAssertNotNil(error)

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        client.close()

        XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.closing)
        ping()
        XCTAssertNotNil(error)

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)
        ping()
        XCTAssertNotNil(error)

        client.internal.onError(AblyTests.newErrorProtocolMessage())

        XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.failed)
        ping()
        XCTAssertNotNil(error)
    }

    // RTN13a
    func test__052__Connection__ping__should_send_a_ProtocolMessage_with_action_HEARTBEAT_and_expects_a_HEARTBEAT_message_in_response() throws {
        let client = AblyTests.newRealtime(try AblyTests.commonAppSetup()).client
        defer { client.dispose(); client.close() }
        waitUntil(timeout: testTimeout) { done in
            client.ping { error in
                XCTAssertNil(error)
                let transport = client.internal.transport as! TestProxyTransport
                XCTAssertEqual(transport.protocolMessagesSent.filter { $0.action == .heartbeat }.count, 1)
                XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .heartbeat }.count, 1)
                done()
            }
        }
    }

    // RTN13c
    func test__053__Connection__ping__should_fail_if_a_HEARTBEAT_ProtocolMessage_is_not_received_within_the_default_realtime_request_timeout() throws {
        let options = try AblyTests.commonAppSetup()
        let realtimeRequestTimeout = 3.0
        options.testOptions.realtimeRequestTimeout = realtimeRequestTimeout
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                done()
            }
        }
        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        transport.actionsIgnored += [.heartbeat]

        waitUntil(timeout: testTimeout) { done in
            let start = NSDate()
            transport.ignoreSends = true

            client.ping { error in
                guard let error = error else {
                    fail("expected error"); done(); return
                }
                let end = NSDate()
                expect(error.message).to(contain("timed out"))
                expect(end.timeIntervalSince(start as Date)).to(beCloseTo(realtimeRequestTimeout, within: 1.5))
                done()
            }
        }
    }

    // RTN14a
    func test__009__Connection__should_enter_FAILED_state_when_API_key_is_invalid() throws {
        let options = try AblyTests.commonAppSetup()
        options.key = String(options.key!.reversed())
        options.autoConnect = false
        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                switch state {
                case .failed:
                    XCTAssertNotNil(errorInfo)
                    done()
                default:
                    break
                }
            }
            client.connect()
        }
    }

    // RTN14b

    func test__054__Connection__connection_request_fails__on_DISCONNECTED_after_CONNECTED__should_not_emit_error_with_a_renewable_token() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.authCallback = { tokenParams, callback in
            getTestTokenDetails(key: options.key, capability: tokenParams.capability, ttl: tokenParams.ttl as! TimeInterval?, completion: callback)
        }
        let tokenTtl = 3.0
        options.token = try getTestToken(key: options.key, ttl: tokenTtl)
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }

        waitUntil(timeout: testTimeout) { done in
            // Let the token expire
            client.connection.once(.disconnected) { stateChange in
                guard let reason = stateChange.reason else {
                    fail("Token error is missing"); done(); return
                }
                XCTAssertEqual(reason.code, ARTErrorCode.tokenExpired.intValue)

                client.connection.on { stateChange in
                    let state = stateChange.current
                    let errorInfo = stateChange.reason
                    switch state {
                    case .connected:
                        XCTAssertNil(errorInfo)
                        // New token
                        XCTAssertNotEqual(client.auth.tokenDetails!.token, options.token)
                        done()
                    case .failed, .suspended:
                        fail("Should not emit error (\(String(describing: errorInfo)))")
                        done()
                    default:
                        break
                    }
                }
            }
            client.connect()
        }
    }

    func test__055__Connection__connection_request_fails__on_token_error_while_CONNECTING__reissues_token_and_reconnects() throws {
        var authCallbackCalled = 0

        var tokenTTL = 1.0

        let options = try AblyTests.commonAppSetup()
        options.authCallback = { _, callback in
            authCallbackCalled += 1
            getTestTokenDetails(ttl: tokenTTL) { token, err in
                // Let the token expire
                delay(2.0) {
                    callback(token, err)
                }
                // Next time, tokenTTL will be longer so that it doesn't expire right away
                tokenTTL = 60
            }
        }
        options.autoConnect = false

        let realtime = ARTRealtime(options: options)
        defer { realtime.close() }

        var hookToken: AspectToken?
        waitUntil(timeout: testTimeout.multiplied(by: 2)) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            realtime.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                partialDone()
            }
            hookToken = realtime.internal.testSuite_getArgument(from: NSSelectorFromString("onError:"), at: 0) { arg0 in
                guard let message = arg0 as? ARTProtocolMessage, let error = message.error else {
                    fail("Expecting a protocol message with Token error"); partialDone(); return
                }
                XCTAssertEqual(error.code, ARTErrorCode.tokenExpired.intValue)
                partialDone()
            }
            realtime.connect()
        }
        hookToken?.remove()

        // First token issue, and then reissue on token error.
        XCTAssertEqual(authCallbackCalled, 2)
    }

    func test__056__Connection__connection_request_fails__should_transition_to_disconnected_when_the_token_renewal_fails() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let tokenTtl = 3.0
        let tokenDetails = try getTestTokenDetails(key: options.key, capability: nil, ttl: tokenTtl)
        options.token = tokenDetails.token
        options.authCallback = { _, callback in
            delay(0) {
                callback(tokenDetails, nil) // Return the same expired token again.
            }
        }

        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                partialDone()
            }
            client.connection.once(.disconnected) { stateChange in
                guard let reason = stateChange.reason else {
                    fail("Reason is nil"); done(); return
                }
                XCTAssertEqual(reason.code, ARTErrorCode.tokenExpired.intValue)
                XCTAssertEqual(reason.statusCode, 401)
                expect(reason.message).to(contain("Key/token status changed (expire)"))
                partialDone()
            }
            client.connect()
        }
    }

    func test__057__Connection__connection_request_fails__should_transition_to_Failed_state_because_the_token_is_invalid_and_not_renewable() throws {
        let options = try AblyTests.clientOptions()
        options.autoConnect = false
        let tokenTtl = 1.0
        options.token = try getTestToken(ttl: tokenTtl)
        options.testOptions.transportFactory = TestProxyTransportFactory()

        // Let the token expire
        waitUntil(timeout: testTimeout) { done in
            delay(tokenTtl) {
                done()
            }
        }

        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }

        var transport: TestProxyTransport!

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                let state = stateChange.current
                let errorInfo = stateChange.reason
                switch state {
                case .connected:
                    fail("Should not be connected")
                    done()
                case .failed, .disconnected, .suspended:
                    guard let errorInfo = errorInfo else {
                        fail("ErrorInfo is nil"); done(); return
                    }
                    XCTAssertEqual(errorInfo.code, ARTErrorCode.tokenExpired.intValue)
                    done()
                default:
                    break
                }
            }
            client.connect()
            transport = (client.internal.transport as! TestProxyTransport)
        }

        let failures = transport.protocolMessagesReceived.filter { $0.action == .error }

        if failures.count != 1 {
            fail("Should have only one connection request fail")
            return
        }

        XCTAssertEqual(failures[0].error!.code, ARTErrorCode.tokenExpired.intValue)
    }

    // RTN14c
    func test__058__Connection__connection_request_fails__connection_attempt_should_fail_if_not_connected_within_the_default_realtime_request_timeout() throws {
        let options = try AblyTests.commonAppSetup()
        options.realtimeHost = "10.255.255.1" // non-routable IP address
        options.autoConnect = false
        let realtimeRequestTimeout = 0.5
        options.testOptions.realtimeRequestTimeout = realtimeRequestTimeout

        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        var start, end: NSDate?
        waitUntil(timeout: testTimeout) { done in
            client.connection.on(.disconnected) { stateChange in
                end = NSDate()
                expect(stateChange.reason!.message).to(contain("timed out"))
                XCTAssertTrue(client.connection.errorReason! === stateChange.reason)
                done()
            }
            client.connect()
            start = NSDate()
        }
        if let start = start, let end = end {
            expect(end.timeIntervalSince(start as Date)).to(beCloseTo(realtimeRequestTimeout, within: 1.5))
        } else {
            fail("Start date or end date are empty")
        }
    }

    // RTN14d
    func test__059__Connection__connection_request_fails__connection_attempt_fails_for_any_recoverable_reason() throws {
        let options = try AblyTests.commonAppSetup()
        options.realtimeHost = "10.255.255.1" // non-routable IP address
        options.disconnectedRetryTimeout = 1.0
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 0.1
        let expectedTime = 3.0

        options.authCallback = { _, _ in
            // Ignore `completion` closure to force a time out
        }

        let previousConnectionStateTtl = ARTDefault.connectionStateTtl()
        defer { ARTDefault.setConnectionStateTtl(previousConnectionStateTtl) }
        ARTDefault.setConnectionStateTtl(expectedTime)

        let client = ARTRealtime(options: options)
        client.internal.shouldImmediatelyReconnect = false
        defer {
            client.connection.off()
            client.close()
        }

        var totalRetry = 0
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            var start: NSDate?

            client.connection.once(.disconnected) { stateChange in
                expect(stateChange.reason!.message).to(contain("timed out"))
                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.connecting)
                expect(stateChange.retryIn).to(beCloseTo(options.disconnectedRetryTimeout))
                partialDone()
                start = NSDate()
            }

            client.connection.on(.suspended) { _ in
                let end = NSDate()
                expect(end.timeIntervalSince(start! as Date)).to(beCloseTo(expectedTime, within: 0.9))
                partialDone()
            }

            client.connect()

            client.connection.on(.connecting) { stateChange in
                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.disconnected)
                totalRetry += 1
            }
        }

        XCTAssertEqual(totalRetry, Int(expectedTime / options.disconnectedRetryTimeout))
    }

    // RTN14e
    func test__060__Connection__connection_request_fails__connection_state_has_been_in_the_DISCONNECTED_state_for_more_than_the_default_connectionStateTtl_should_change_the_state_to_SUSPENDED() throws {
        let options = try AblyTests.commonAppSetup()
        options.disconnectedRetryTimeout = 0.1
        options.suspendedRetryTimeout = 0.5
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 0.1

        options.authCallback = { _, _ in
            // Force a timeout
        }

        let client = ARTRealtime(options: options)
        client.internal.shouldImmediatelyReconnect = false
        defer { client.dispose(); client.close() }

        let ttlHookToken = client.overrideConnectionStateTTL(0.3)
        defer { ttlHookToken.remove() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on(.suspended) { _ in
                expect(client.connection.errorReason!.message).to(contain("timed out"))

                let start = NSDate()
                client.connection.once(.connecting) { _ in
                    let end = NSDate()
                    expect(end.timeIntervalSince(start as Date)).to(beCloseTo(options.suspendedRetryTimeout, within: 0.5))
                    done()
                }
            }
            client.connect()
        }
    }

    // RTN14e - https://github.com/ably/ably-cocoa/issues/913
    func test__061__Connection__connection_request_fails__should_change_the_state_to_SUSPENDED_when_the_connection_state_has_been_in_the_DISCONNECTED_state_for_more_than_the_connectionStateTtl() throws {
        let options = try AblyTests.commonAppSetup()
        options.disconnectedRetryTimeout = 0.5
        options.suspendedRetryTimeout = 2.0
        options.autoConnect = false
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory

        let client = ARTRealtime(options: options)
        client.internal.setReachabilityClass(TestReachability.self)
        defer {
            client.simulateRestoreInternetConnection(transportFactory: transportFactory)
            client.dispose()
            client.close()
        }

        let ttlHookToken = client.overrideConnectionStateTTL(3.0)
        defer { ttlHookToken.remove() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
            client.connect()
        }

        var events: [ARTRealtimeConnectionState] = []
        client.connection.on { stateChange in
            events.append(stateChange.current)
        }
        client.simulateNoInternetConnection(transportFactory: transportFactory)

        expect(events).toEventually(equal([
            .disconnected,
            .connecting, // 0.5 - 1
            .disconnected,
            .connecting, // 1.0 - 2
            .disconnected,
            .connecting, // 1.5 - 3
            .disconnected,
            .connecting, // 2.0 - 4
            .disconnected,
            .connecting, // 2.5 - 5
            .disconnected,
            .connecting, // 3.0 - 6
            .suspended,
            .connecting,
            .suspended,
        ]), timeout: testTimeout)

        events.removeAll()
        client.simulateRestoreInternetConnection(after: 7.0, transportFactory: transportFactory)

        expect(events).toEventually(equal([
            .connecting, // 2.0 - 1
            .suspended,
            .connecting, // 4.0 - 2
            .suspended,
            .connecting, // 6.0 - 3
            .suspended,
            .connecting,
            .connected,
        ]), timeout: testTimeout)

        client.connection.off()

        XCTAssertNil(client.connection.errorReason)
        XCTAssertEqual(client.connection.state, .connected)
    }

    func test__062__Connection__connection_request_fails__on_CLOSE_the_connection_should_stop_connection_retries() throws {
        let options = try AblyTests.commonAppSetup()
        // to avoid waiting for the default 15s before trying a reconnection
        options.disconnectedRetryTimeout = 0.1
        options.suspendedRetryTimeout = 0.5
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 0.1
        let expectedTime: TimeInterval = 1.0

        options.authCallback = { _, _ in
            // Force a timeout
        }

        let previousConnectionStateTtl = ARTDefault.connectionStateTtl()
        defer { ARTDefault.setConnectionStateTtl(previousConnectionStateTtl) }
        ARTDefault.setConnectionStateTtl(expectedTime)

        let client = ARTRealtime(options: options)
        client.internal.shouldImmediatelyReconnect = false
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on(.suspended) { _ in
                expect(client.connection.errorReason!.message).to(contain("timed out"))

                let start = NSDate()
                client.connection.once(.connecting) { _ in
                    let end = NSDate()
                    expect(end.timeIntervalSince(start as Date)).to(beCloseTo(options.suspendedRetryTimeout, within: 0.5))
                    done()
                }
            }
            client.connect()
        }

        client.close()

        // Check if the connection gets closed
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connecting) { _ in
                fail("Should be closing the connection"); done()
            }
            delay(2.0) {
                done()
            }
        }
    }

    // RTN15

    // RTN15a
    func test__063__Connection__connection_failures_once_CONNECTED__should_not_receive_published_messages_until_the_connection_reconnects_successfully() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false

        let client1 = ARTRealtime(options: options)
        defer { client1.close() }
        
        let channelName = uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        var states = [ARTRealtimeConnectionState]()
        client1.connection.on { stateChange in
            states = states + [stateChange.current]
        }
        client1.connect()

        let client2 = ARTRealtime(options: options)
        client2.connect()
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        channel1.subscribe { _ in
            fail("Shouldn't receive the messsage")
        }

        expect(channel1.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        let firstConnection: (id: String, key: String) = (client1.connection.id!, client1.connection.key!)

        // Connection state cannot be resumed
        client1.simulateLostConnectionAndState()

        channel2.publish(nil, data: "message") { errorInfo in
            XCTAssertNil(errorInfo)
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            client1.connection.once(.connecting) { _ in
                XCTAssertTrue(client1.internal.resuming)
                partialDone()
            }
            client1.connection.once(.connected) { _ in
                XCTAssertFalse(client1.internal.resuming)
                XCTAssertNotEqual(client1.connection.id, firstConnection.id)
                XCTAssertNotEqual(client1.connection.key, firstConnection.key)
                partialDone()
            }
        }

        expect(states).toEventually(equal([.connecting, .connected, .disconnected, .connecting, .connected]), timeout: testTimeout)
    }

    // RTN15a
    func test__064__Connection__connection_failures_once_CONNECTED__if_a_Connection_transport_is_disconnected_unexpectedly_or_if_a_token_expires__then_the_Connection_manager_will_immediately_attempt_to_reconnect() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                // Simulate interruption shortly
                delay(1.0) {
                    client.internal.onDisconnected()
                }
            }
            client.connection.on(.disconnected) { _ in
                let disconnectedTime = Date()
                client.connection.on(.connected) { _ in
                    let reconnectedTime = Date()
                    // test that reconnection happens within 10 seconds,
                    // so that we are sure it doesn't wait for the default 15s
                    expect(reconnectedTime.timeIntervalSince(disconnectedTime)).to(beCloseTo(0, within: 10))
                    done()
                }
            }
            client.connect()
        }
    }

    // RTN15b

    // RTN15b1, RTN15b2
    func test__067__Connection__connection_failures_once_CONNECTED__reconnects_to_the_websocket_endpoint_with_additional_querystring_params__resume_is_the_private_connection_key_and_connection_serial_is_the_most_recent_ProtocolMessage_connectionSerial_received() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        let expectedConnectionKey = client.connection.key!
        let expectedConnectionSerial = client.connection.serial
        client.internal.onDisconnected()

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                let transport = client.internal.transport as! TestProxyTransport
                let query = transport.lastUrl!.query
                expect(query).to(haveParam("resume", withValue: expectedConnectionKey))
                expect(query).to(haveParam("connectionSerial", withValue: "\(expectedConnectionSerial)"))
                done()
            }
        }
    }

    // RTN15c

    // RTN15c1
    func test__068__Connection__connection_failures_once_CONNECTED__System_s_response_to_a_resume_request__CONNECTED_ProtocolMessage_with_the_same_connectionId_as_the_current_client__and_no_error() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        let expectedConnectionId = client.connection.id
        client.internal.onDisconnected()

        channel.attach()
        channel.publish(nil, data: "queued message")
        expect(client.internal.queuedMessages).toEventually(haveCount(1), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                let transport = client.internal.transport as! TestProxyTransport
                let connectedPM = transport.protocolMessagesReceived.filter { $0.action == .connected }[0]
                XCTAssertEqual(connectedPM.connectionId, expectedConnectionId)
                XCTAssertNil(stateChange.reason)
                done()
            }
        }
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
        expect(client.internal.queuedMessages).toEventually(haveCount(0), timeout: testTimeout)
    }

    // RTN15c2
    func test__069__Connection__connection_failures_once_CONNECTED__System_s_response_to_a_resume_request__CONNECTED_ProtocolMessage_with_the_same_connectionId_as_the_current_client_and_an_non_fatal_error() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        let expectedConnectionId = client.connection.id
        client.internalAsync { _internal in
            _internal.onDisconnected()
        }

        channel.attach()
        channel.publish(nil, data: "queued message")
        expect(client.internal.queuedMessages).toEventually(haveCount(1), timeout: testTimeout)

        client.connection.once(.connecting) { _ in
            client.internalSync { _internal in
                let transport = _internal.transport as! TestProxyTransport
                transport.setBeforeIncomingMessageModifier { protocolMessage in
                    if protocolMessage.action == .connected {
                        protocolMessage.error = .create(withCode: 0, message: "Injected error")
                    } else if protocolMessage.action == .attached {
                        protocolMessage.error = .create(withCode: 0, message: "Channel injected error")
                    }
                    return protocolMessage
                }
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            client.connection.once(.connected) { stateChange in
                XCTAssertEqual(stateChange.reason?.message, "Injected error")
                XCTAssertTrue(client.connection.errorReason === stateChange.reason)
                let transport = client.internal.transport as! TestProxyTransport
                let connectedPM = transport.protocolMessagesReceived.filter { $0.action == .connected }[0]
                XCTAssertEqual(connectedPM.connectionId, expectedConnectionId)
                XCTAssertEqual(client.connection.id, expectedConnectionId)
                partialDone()
            }
            channel.once(.attached) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Reason error is nil"); done(); return
                }
                XCTAssertEqual(error.message, "Channel injected error")
                XCTAssertTrue(channel.errorReason === error)
                partialDone()
            }
        }

        expect(client.internal.queuedMessages).toEventually(haveCount(0), timeout: testTimeout)
    }

    // RTN15c3
    func test__070__Connection__connection_failures_once_CONNECTED__System_s_response_to_a_resume_request__CONNECTED_ProtocolMessage_with_a_new_connectionId_and_an_error() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
        }

        let oldConnectionId = client.connection.id

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)

            channel.once(.attaching) { _ in
                XCTAssertNil(channel.errorReason)
                partialDone()
            }

            client.connection.once(.connected) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Connection resume failed and error should be propagated to the channel"); done(); return
                }
                XCTAssertEqual(error.code, ARTErrorCode.unableToRecoverConnectionExpired.intValue)
                expect(error.message).to(contain("Unable to recover connection"))
                XCTAssertTrue(client.connection.errorReason === stateChange.reason)
                partialDone()
            }

            client.simulateLostConnectionAndState()
        }

        let transport = client.internal.transport as! TestProxyTransport
        let connectedPM = transport.protocolMessagesReceived.filter { $0.action == .connected }[0]
        XCTAssertNotEqual(connectedPM.connectionId, oldConnectionId)
        XCTAssertEqual(client.connection.id, connectedPM.connectionId)
        XCTAssertEqual(client.internal.msgSerial, 0)

        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
    }

    // RTN15c4
    func test__071__Connection__connection_failures_once_CONNECTED__System_s_response_to_a_resume_request__ERROR_ProtocolMessage_indicating_a_fatal_error_in_the_connection() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        client.internal.onDisconnected()

        let protocolError = AblyTests.newErrorProtocolMessage()
        client.connection.once(.connecting) { _ in
            // Resuming
            guard let transport = client.internal.transport as? TestProxyTransport else {
                fail("TestProxyTransport is not set"); return
            }
            transport.actionsIgnored += [.connected]
            client.internal.onError(protocolError)
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.failed) { stateChange in
                XCTAssertTrue(stateChange.reason === protocolError.error)
                XCTAssertTrue(client.connection.errorReason === protocolError.error)
                done()
            }
        }
        XCTAssertEqual(channel.state, ARTRealtimeChannelState.failed)
        XCTAssertTrue(channel.errorReason === protocolError.error)
    }

    func skipped__test__072__Connection__connection_failures_once_CONNECTED__System_s_response_to_a_resume_request__should_resume_the_connection_after_an_auth_renewal() throws {
        let options = try AblyTests.commonAppSetup()
        options.tokenDetails = try getTestTokenDetails(ttl: 5.0)
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let restOptions = try AblyTests.clientOptions(key: options.key!)
        restOptions.testOptions.channelNamePrefix = options.testOptions.channelNamePrefix
        let rest = ARTRest(options: restOptions)
        
        let channelName = uniqueChannelName()
        let channel = client.channels.get(channelName)
        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
        }

        let initialConnectionId = client.connection.id

        guard let _ = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        channel.once(.detached) { _ in
            fail("Should not detach channels")
        }
        defer { channel.off() }

        waitUntil(timeout: testTimeout) { done in
            // Wait for token to expire
            client.connection.once(.disconnected) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Error is nil"); done(); return
                }
                XCTAssertEqual(error.code, ARTErrorCode.tokenExpired.intValue)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            // Wait for connection resume
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
        }

        guard let secondTransport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        let connectedMessages = secondTransport.protocolMessagesReceived.filter { $0.action == .connected }
        XCTAssertEqual(connectedMessages.count, 1) // New transport connected
        guard let receivedConnectionId = connectedMessages.first?.connectionId else {
            fail("ConnectionID is nil"); return
        }
        XCTAssertEqual(client.connection.id, receivedConnectionId)
        XCTAssertEqual(client.connection.id, initialConnectionId)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            let expectedMessage = ARTMessage(name: "ios", data: "message1")

            channel.subscribe { message in
                XCTAssertEqual(message.name, expectedMessage.name)
                XCTAssertEqual(message.data as? String, expectedMessage.data as? String)
                partialDone()
            }

            rest.channels.get(channelName).publish([expectedMessage]) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }
    }

    // FIXME: Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
    // RTN15d
    func skipped__test__065__Connection__connection_failures_once_CONNECTED__should_recover_from_disconnection_and_messages_should_be_delivered_once_the_connection_is_resumed() throws {
        let options = try AblyTests.commonAppSetup()

        let client1 = ARTRealtime(options: options)
        defer { client1.close() }
        
        let channelName = uniqueChannelName()
        let channel1 = client1.channels.get(channelName)

        let client2 = ARTRealtime(options: options)
        defer { client2.close() }
        let channel2 = client2.channels.get(channelName)

        let expectedMessages = ["message X", "message Y"]
        var receivedMessages = [String]()

        waitUntil(timeout: testTimeout) { done in
            channel1.subscribe(attachCallback: { errorInfo in
                XCTAssertNil(errorInfo)
                done()
            }, callback: { message in
                receivedMessages.append(message.data as! String)
            })
        }

        client1.internal.onDisconnected()

        channel2.publish(expectedMessages.map { ARTMessage(name: nil, data: $0) }) { errorInfo in
            XCTAssertNil(errorInfo)
        }

        waitUntil(timeout: testTimeout) { done in
            client1.connection.once(.connecting) { _ in
                expect(receivedMessages).to(beEmpty())
                done()
            }
        }

        expect(client1.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        expect(receivedMessages).toEventually(equal(expectedMessages), timeout: testTimeout)
    }

    // RTN15e

    func test__073__Connection__connection_failures_once_CONNECTED__when_a_connection_is_resumed__the_connection_key_may_change_and_will_be_provided_in_the_first_CONNECTED_ProtocolMessage_connectionDetails() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        client.connect()
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())

        channel.attach()
        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)

        client.internal.onDisconnected()

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connecting) { _ in
                client.connection.internal.setKey("key_to_be_replaced")
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                let transport = client.internal.transport as! TestProxyTransport
                let firstConnectionDetails = transport.protocolMessagesReceived.filter { $0.action == .connected }[0].connectionDetails
                XCTAssertNotNil(firstConnectionDetails!.connectionKey)
                XCTAssertEqual(client.connection.key, firstConnectionDetails!.connectionKey)
                done()
            }
        }
    }

    // RTN15f
    func test__066__Connection__connection_failures_once_CONNECTED__ACK_and_NACK_responses_for_published_messages_can_only_ever_be_received_on_the_transport_connection_on_which_those_messages_were_sent() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())

        var resumed = false
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)

            guard let transport1 = client.internal.transport as? TestProxyTransport else {
                fail("TestProxyTransport not setup"); done(); return
            }

            var sentPendingMessage: ARTMessage?
            channel.publish(nil, data: "message") { _ in
                if resumed {
                    guard let transport2 = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport not setup"); done(); return
                    }
                    XCTAssertEqual(transport2.protocolMessagesReceived.filter { $0.action == .ack }.count, 1)

                    guard let _ = transport1.protocolMessagesSent.filter({ $0.action == .message }).first?.messages?.first else {
                        fail("Message that has been re-sent isn't available"); done(); return
                    }
                    guard let sentTransportMessage2 = transport2.protocolMessagesSent.filter({ $0.action == .message }).first?.messages?.first else {
                        fail("Message that has been re-sent isn't available"); done(); return
                    }

                    expect(transport1).toNot(beIdenticalTo(transport2))
                    XCTAssertTrue(sentPendingMessage === sentTransportMessage2)

                    partialDone()
                } else {
                    fail("Shouldn't be called")
                }
            }
            AblyTests.queue.async {
                client.internal.onDisconnected()
            }
            client.connection.once(.connected) { _ in
                resumed = true
            }
            client.internal.testSuite_injectIntoMethod(before: Selector(("resendPendingMessages"))) {
                XCTAssertEqual(client.internal.pendingMessages.count, 1)
                let pm: ARTProtocolMessage? = (client.internal.pendingMessages.firstObject as? ARTPendingMessage)?.msg
                sentPendingMessage = pm?.messages?[0]
            }
            client.internal.testSuite_injectIntoMethod(after: Selector(("resendPendingMessages"))) {
                partialDone()
            }
        }
    }

    // RTN15g RTN15g1

    func skipped__test__074__Connection__connection_failures_once_CONNECTED__when_connection__ttl_plus_idle_interval__period_has_passed_since_last_activity__uses_a_new_connection() throws {
        let options = try AblyTests.commonAppSetup()
        // We want this to be > than the sum of customTtlInterval and customIdleInterval
        options.disconnectedRetryTimeout = 5.0 + customTtlInterval + customIdleInterval
        ttlAndIdleIntervalPassedTestsClient = AblyTests.newRealtime(options).client
        ttlAndIdleIntervalPassedTestsClient.internal.shouldImmediatelyReconnect = false
        ttlAndIdleIntervalPassedTestsClient.connect()
        defer { ttlAndIdleIntervalPassedTestsClient.close() }

        waitUntil(timeout: testTimeout) { done in
            ttlAndIdleIntervalPassedTestsClient.connection.once(.connected) { _ in
                XCTAssertNotNil(ttlAndIdleIntervalPassedTestsClient.connection.id)
                ttlAndIdleIntervalPassedTestsConnectionId = ttlAndIdleIntervalPassedTestsClient.connection.id!
                ttlAndIdleIntervalPassedTestsClient.internal.connectionStateTtl = customTtlInterval
                ttlAndIdleIntervalPassedTestsClient.internal.maxIdleInterval = customIdleInterval
                ttlAndIdleIntervalPassedTestsClient.connection.once(.disconnected) { _ in
                    let disconnectedAt = Date()
                    XCTAssertEqual(ttlAndIdleIntervalPassedTestsClient.internal.connectionStateTtl, customTtlInterval)
                    XCTAssertEqual(ttlAndIdleIntervalPassedTestsClient.internal.maxIdleInterval, customIdleInterval)
                    ttlAndIdleIntervalPassedTestsClient.connection.once(.connecting) { _ in
                        let reconnectionInterval = Date().timeIntervalSince(disconnectedAt)
                        expect(reconnectionInterval).to(beGreaterThan(ttlAndIdleIntervalPassedTestsClient.internal.connectionStateTtl + ttlAndIdleIntervalPassedTestsClient.internal.maxIdleInterval))
                        ttlAndIdleIntervalPassedTestsClient.connection.once(.connected) { _ in
                            XCTAssertNotEqual(ttlAndIdleIntervalPassedTestsClient.connection.id, ttlAndIdleIntervalPassedTestsConnectionId)
                            done()
                        }
                    }
                }
                ttlAndIdleIntervalPassedTestsClient.internal.onDisconnected()
            }
        }
    }

    // RTN15g3
    func test__075__Connection__connection_failures_once_CONNECTED__when_connection__ttl_plus_idle_interval__period_has_passed_since_last_activity__reattaches_to_the_same_channels_after_a_new_connection_has_been_established() throws {
        let options = try AblyTests.commonAppSetup()
        // We want this to be > than the sum of customTtlInterval and customIdleInterval
        options.disconnectedRetryTimeout = 5.0
        ttlAndIdleIntervalPassedTestsClient = AblyTests.newRealtime(options).client
        ttlAndIdleIntervalPassedTestsClient.internal.shouldImmediatelyReconnect = false
        defer { ttlAndIdleIntervalPassedTestsClient.close() }
        let channelName = uniqueChannelName()
        let channel = ttlAndIdleIntervalPassedTestsClient.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            ttlAndIdleIntervalPassedTestsClient.connection.once(.connected) { _ in
                ttlAndIdleIntervalPassedTestsConnectionId = ttlAndIdleIntervalPassedTestsClient.connection.id!
                ttlAndIdleIntervalPassedTestsClient.internal.connectionStateTtl = customTtlInterval
                ttlAndIdleIntervalPassedTestsClient.internal.maxIdleInterval = customIdleInterval
                channel.attach { error in
                    if let error = error {
                        fail(error.message)
                    }
                    XCTAssertEqual(channel.state, ARTRealtimeChannelState.attached)
                    ttlAndIdleIntervalPassedTestsClient.internal.onDisconnected()
                }
                ttlAndIdleIntervalPassedTestsClient.connection.once(.disconnected) { _ in
                    ttlAndIdleIntervalPassedTestsClient.connection.once(.connecting) { _ in
                        ttlAndIdleIntervalPassedTestsClient.connection.once(.connected) { _ in
                            XCTAssertNotEqual(ttlAndIdleIntervalPassedTestsClient.connection.id, ttlAndIdleIntervalPassedTestsConnectionId)
                            channel.once(.attached) { stateChange in
                                XCTAssertFalse(stateChange.resumed)
                                done()
                            }
                        }
                    }
                }
            }
            ttlAndIdleIntervalPassedTestsClient.connect()
        }
    }

    // RTN15g2

    func test__076__Connection__connection_failures_once_CONNECTED__when_connection__ttl_plus_idle_interval__period_has_NOT_passed_since_last_activity__uses_the_same_connection() throws {
        let options = try AblyTests.commonAppSetup()
        ttlAndIdleIntervalNotPassedTestsClient = AblyTests.newRealtime(options).client
        ttlAndIdleIntervalNotPassedTestsClient.connect()
        defer { ttlAndIdleIntervalNotPassedTestsClient.close() }

        waitUntil(timeout: testTimeout) { done in
            ttlAndIdleIntervalNotPassedTestsClient.connection.once(.connected) { _ in
                XCTAssertNotNil(ttlAndIdleIntervalNotPassedTestsClient.connection.id)
                ttlAndIdleIntervalNotPassedTestsConnectionId = ttlAndIdleIntervalNotPassedTestsClient.connection.id!
                ttlAndIdleIntervalNotPassedTestsClient.connection.once(.disconnected) { _ in
                    let disconnectedAt = Date()
                    ttlAndIdleIntervalNotPassedTestsClient.connection.once(.connecting) { _ in
                        let reconnectionInterval = Date().timeIntervalSince(disconnectedAt)
                        expect(reconnectionInterval).to(beLessThan(ttlAndIdleIntervalNotPassedTestsClient.internal.connectionStateTtl + ttlAndIdleIntervalNotPassedTestsClient.internal.maxIdleInterval))
                        ttlAndIdleIntervalNotPassedTestsClient.connection.once(.connected) { _ in
                            XCTAssertEqual(ttlAndIdleIntervalNotPassedTestsClient.connection.id, ttlAndIdleIntervalNotPassedTestsConnectionId)
                            done()
                        }
                    }
                }
                ttlAndIdleIntervalNotPassedTestsClient.internal.onDisconnected()
            }
        }
    }

    // RTN15h

    func skipped__test__077__Connection__connection_failures_once_CONNECTED__DISCONNECTED_message_contains_a_token_error__if_the_token_is_renewable_then_error_should_not_be_emitted() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.authCallback = { tokenParams, callback in
            getTestTokenDetails(key: options.key, capability: tokenParams.capability, ttl: TimeInterval(60 * 60), completion: callback)
        }
        let tokenTtl = 2.0
        options.token = try getTestToken(key: options.key, ttl: tokenTtl)
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }

        client.connect()
        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
        let firstTransport = client.internal.transport as? TestProxyTransport

        waitUntil(timeout: testTimeout) { done in
            // Wait for token to expire
            client.connection.once(.disconnected) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Error is nil"); done(); return
                }
                XCTAssertEqual(error.code, ARTErrorCode.tokenExpired.intValue)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
        }
        XCTAssertNil(client.connection.errorReason)

        // New connection
        XCTAssertNotNil(client.internal.transport)
        expect(client.internal.transport).toNot(beIdenticalTo(firstTransport))

        waitUntil(timeout: testTimeout) { done in
            client.ping { error in
                XCTAssertNil(error)
                XCTAssertEqual((client.internal.transport as! TestProxyTransport).protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                done()
            }
        }
    }

    // RTN15h1
    func test__078__Connection__connection_failures_once_CONNECTED__DISCONNECTED_message_contains_a_token_error__and_the_library_does_not_have_a_means_to_renew_the_token__the_connection_will_transition_to_the_FAILED_state() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let key = options.key
        // set the key to nil so that the client can't sign further token requests
        options.key = nil
        let tokenTtl = 3.0
        let tokenDetails = try getTestTokenDetails(key: key, ttl: tokenTtl)
        options.token = tokenDetails.token
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.failed) { stateChange in
                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.reason?.code, ARTErrorCode.tokenExpired.intValue)
                done()
            }
            client.connect()
        }
    }

    // RTN15h2
    func skipped__test__079__Connection__connection_failures_once_CONNECTED__DISCONNECTED_message_contains_a_token_error__should_transition_to_disconnected_when_the_token_renewal_fails_and_the_error_should_be_emitted() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let tokenTtl = 3.0
        let tokenDetails = try getTestTokenDetails(key: options.key, capability: nil, ttl: tokenTtl)
        options.token = tokenDetails.token
        options.authCallback = { _, callback in
            delay(0.1) {
                callback(tokenDetails, nil) // Return the same expired token again.
            }
        }
        options.testOptions.transportFactory = TestProxyTransportFactory()

        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }

        waitUntil(timeout: testTimeout) { done in
            // Wait for token to expire
            client.connection.once(.disconnected) { stateChange in
                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.connected)
                guard let error = stateChange.reason else {
                    fail("Error is nil"); done(); return
                }
                XCTAssertEqual(error.code, ARTErrorCode.tokenExpired.intValue)

                // Renewal will lead to another disconnection
                client.connection.once(.disconnected) { stateChange in
                    guard let error = stateChange.reason else {
                        fail("Error is nil"); done(); return
                    }
                    XCTAssertEqual(error.code, ARTErrorCode.tokenExpired.intValue)
                    XCTAssertTrue(client.connection.errorReason === error)
                    done()
                }
            }

            client.connect()
        }
    }

    // RTN16

    // RTN16a
    func test__080__Connection__Connection_recovery__connection_state_should_recover_explicitly_with_a_recover_key() throws {
        let options = try AblyTests.commonAppSetup()

        let clientSend = ARTRealtime(options: options)
        defer { clientSend.close() }
        
        let channelName = uniqueChannelName()
        let channelSend = clientSend.channels.get(channelName)

        let clientReceive = ARTRealtime(options: options)
        defer { clientReceive.close() }
        let channelReceive = clientReceive.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channelReceive.subscribe(attachCallback: { error in
                XCTAssertNil(error)
                channelSend.publish(nil, data: "message") { error in
                    XCTAssertNil(error)
                }
            }, callback: { message in
                XCTAssertEqual(message.data as? String, "message")
                done()
            })
        }

        options.recover = clientReceive.connection.recoveryKey
        clientReceive.internal.onError(AblyTests.newErrorProtocolMessage())

        waitUntil(timeout: testTimeout) { done in
            channelSend.publish(nil, data: "queue a message") { error in
                XCTAssertNil(error)
                done()
            }
        }

        let clientRecover = ARTRealtime(options: options)
        defer { clientRecover.close() }
        let channelRecover = clientRecover.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channelRecover.subscribe { message in
                XCTAssertEqual(message.data as? String, "queue a message")
                done()
            }
        }
    }

    // RTN16b
    func test__081__Connection__Connection_recovery__Connection_recoveryKey_should_be_composed_with_the_connection_key_and_latest_serial_received_and_msgSerial() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(3, done: done)
            client.connection.once(.connected) { _ in
                XCTAssertEqual(client.connection.serial, -1)
                XCTAssertEqual(client.connection.recoveryKey, "\(client.connection.key!):\(client.connection.serial):\(client.internal.msgSerial)")
                partialDone()
            }
            channel.subscribe(attachCallback: { error in
                XCTAssertNil(error)
                
                channel.publish(nil, data: "message") { error in
                    XCTAssertNil(error)
                    partialDone()
                }
            }, callback: { message in
                XCTAssertEqual(message.data as? String, "message")
                XCTAssertEqual(client.connection.serial, 0)
                channel.unsubscribe()
                partialDone()
            })
        }
        XCTAssertEqual(client.internal.msgSerial, 1)
        XCTAssertEqual(client.connection.recoveryKey, "\(client.connection.key!):\(client.connection.serial):\(client.internal.msgSerial)")
    }

    // RTN16d
    func test__082__Connection__Connection_recovery__when_a_connection_is_successfully_recovered__Connection_id_will_be_identical_to_the_id_of_the_connection_that_was_recovered_and_Connection_key_will_always_be_updated_to_the_ConnectionDetails_connectionKey_provided_in_the_first_CONNECTED_ProtocolMessage() throws {
        let options = try AblyTests.commonAppSetup()
        let clientOriginal = ARTRealtime(options: options)
        defer { clientOriginal.close() }

        expect(clientOriginal.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        let expectedConnectionId = clientOriginal.connection.id

        options.recover = clientOriginal.connection.recoveryKey
        clientOriginal.internal.onError(AblyTests.newErrorProtocolMessage())

        let clientRecover = AblyTests.newRealtime(options).client
        defer { clientRecover.close() }

        waitUntil(timeout: testTimeout) { done in
            clientRecover.connection.once(.connected) { _ in
                let transport = clientRecover.internal.transport as! TestProxyTransport
                let firstConnectionDetails = transport.protocolMessagesReceived.filter { $0.action == .connected }.first!.connectionDetails
                XCTAssertNotNil(firstConnectionDetails!.connectionKey)
                XCTAssertEqual(clientRecover.connection.id, expectedConnectionId)
                XCTAssertEqual(clientRecover.connection.key, firstConnectionDetails!.connectionKey)
                done()
            }
        }
    }

    // RTN16c
    func skipped__test__083__Connection__Connection_recovery__Connection_recoveryKey_should_become_becomes_null_when_a_connection_is_explicitly_CLOSED_or_CLOSED() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { _ in
                client.connection.once(.closed) { _ in
                    XCTAssertNil(client.connection.recoveryKey)
                    XCTAssertNil(client.connection.key)
                    XCTAssertNil(client.connection.id)
                    done()
                }
                client.close()
            }
        }
    }

    // RTN16e
    func test__084__Connection__Connection_recovery__should_connect_anyway_if_the_recoverKey_is_no_longer_valid() throws {
        let options = try AblyTests.commonAppSetup()
        options.recover = "99999!xxxxxx-xxxxxxxxx-xxxxxxxxx:-1"
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                guard let reason = stateChange.reason else {
                    fail("Reason is empty"); done(); return
                }
                expect(reason.message).to(contain("Unable to recover connection"))
                XCTAssertTrue(client.connection.errorReason === reason)
                done()
            }
        }
    }

    // RTN16f
    func test__085__Connection__Connection_recovery__should_use_msgSerial_from_recoveryKey_to_set_the_client_internal_msgSerial_but_is_not_sent_to_Ably() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.recover = "99999!xxxxxx-xxxxxxxxx-xxxxxxxxx:-1:7"

        let testEnvironment = AblyTests.newRealtime(options)
        let client = testEnvironment.client
        defer { client.dispose(); client.close() }

        var urlConnections = [URL]()
        testEnvironment.transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
            if urlConnections.count == 1 {
                testEnvironment.transportFactory.networkConnectEvent = nil
            }
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                guard let reason = stateChange.reason else {
                    fail("Reason is empty"); done(); return
                }

                XCTAssertEqual(urlConnections.count, 1)
                guard let urlConnectionQuery = urlConnections.first?.query else {
                    fail("Missing URL Connection query"); done(); return
                }

                expect(urlConnectionQuery).to(haveParam("recover", withValue: "99999!xxxxxx-xxxxxxxxx-xxxxxxxxx"))
                expect(urlConnectionQuery).to(haveParam("connectionSerial", withValue: "-1"))
                expect(urlConnectionQuery).toNot(haveParam("msgSerial"))

                // recover fails, the counter should be reset to 0
                XCTAssertEqual(client.internal.msgSerial, 0)

                expect(reason.message).to(contain("Unable to recover connection"))
                XCTAssertTrue(client.connection.errorReason === reason)
                done()
            }
            client.connect()
            XCTAssertEqual(client.internal.msgSerial, 7)
        }
    }

    // RTN17b
    @available(*, deprecated, message: "This test is marked as deprecated so as to not trigger a compiler warning for using the -ARTClientOptions.fallbackHostsUseDefault property. Remove this deprecation when removing the property.")
    func test__086__Connection__Host_Fallback__failing_connections_with_custom_endpoint_should_result_in_an_error_immediately() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.environment = "test" // do not use the default endpoint
        XCTAssertFalse(options.fallbackHostsUseDefault)
        XCTAssertNil(options.fallbackHosts)
        options.autoConnect = false
        options.queueMessages = false

        let testEnvironment = AblyTests.newRealtime(options)
        let client = testEnvironment.client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())

        testEnvironment.transportFactory.fakeNetworkResponse = .hostUnreachable

        var urlConnections = [URL]()
        testEnvironment.transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.disconnected) { stateChange in
                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.connecting)
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.disconnected)
                guard let reason = stateChange.reason else {
                    fail("Reason is empty"); done(); return
                }
                expect(reason.message).to(contain("host unreachable"))
                done()
            }
            client.connect()
        }

        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: "message") { error in
                XCTAssertEqual(error?.code, 2)
                expect(error?.message).to(contain("host unreachable"))
                expect(error?.reason).to(contain(".FakeNetworkResponse"))
                done()
            }
        }

        XCTAssertEqual(urlConnections.count, 1)
    }

    // RTN17b
    @available(*, deprecated, message: "This test is marked as deprecated so as to not trigger a compiler warning for using the -ARTClientOptions.fallbackHostsUseDefault property. Remove this deprecation when removing the property.")
    func test__087__Connection__Host_Fallback__failing_connections_with_custom_endpoint_should_result_in_time_outs() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.environment = "test" // do not use the default endpoint
        options.testOptions.realtimeRequestTimeout = 1.0
        XCTAssertFalse(options.fallbackHostsUseDefault)
        XCTAssertNil(options.fallbackHosts)
        options.autoConnect = false

        let testEnvironment = AblyTests.newRealtime(options)
        let client = testEnvironment.client
        defer { client.dispose(); client.close() }
        client.channels.get(uniqueChannelName())

        testEnvironment.transportFactory.fakeNetworkResponse = .hostUnreachable

        var urlConnections = [URL]()
        testEnvironment.transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on(.disconnected) { stateChange in
                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.connecting)
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.disconnected)
                guard let reason = stateChange.reason else {
                    fail("Reason is empty"); done(); return
                }
                expect(reason.message).to(contain("host unreachable"))
                done()
            }
            client.connect()
        }

        XCTAssertEqual(urlConnections.count, 1)
    }

    // RTN17b
    func test__088__Connection__Host_Fallback__applies_when_the_default_realtime_ably_io_endpoint_is_being_used() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 1.0
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        client.channels.get(uniqueChannelName())

        transportFactory.fakeNetworkResponse = .hostUnreachable

        var urlConnections = [URL]()
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
            if urlConnections.count == 1 {
                transportFactory.fakeNetworkResponse = nil
            }
        }

        waitUntil(timeout: testTimeout) { done in
            // wss://[a-e].ably-realtime.com: when a timeout occurs
            client.connection.once(.disconnected) { _ in
                done()
            }
            // wss://[a-e].ably-realtime.com: when a 401 occurs because of the `xxxx:xxxx` key
            client.connection.once(.failed) { _ in
                done()
            }
            client.connect()
        }

        XCTAssertEqual(urlConnections.count, 2)
        if urlConnections.count != 2 {
            return
        }
        XCTAssertTrue(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io"))
        XCTAssertTrue(NSRegularExpression.match(urlConnections[1].absoluteString, pattern: "//[a-e].ably-realtime.com"))
    }

    func test__089__Connection__Host_Fallback__applies_when_an_array_of_ClientOptions_fallbackHosts_is_provided() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.fallbackHosts = ["f.ably-realtime.com", "g.ably-realtime.com", "h.ably-realtime.com", "i.ably-realtime.com", "j.ably-realtime.com"]
        options.testOptions.realtimeRequestTimeout = 1.0
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        client.channels.get(uniqueChannelName())

        transportFactory.fakeNetworkResponse = .hostUnreachable

        var urlConnections = [URL]()
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
            if urlConnections.count == 1 {
                transportFactory.fakeNetworkResponse = nil
            }
        }

        waitUntil(timeout: testTimeout) { done in
            // wss://[a-e].ably-realtime.com: when a timeout occurs
            client.connection.once(.disconnected) { _ in
                done()
            }
            // wss://[a-e].ably-realtime.com: when a 401 occurs because of the `xxxx:xxxx` key
            client.connection.once(.failed) { _ in
                done()
            }
            client.connect()
        }

        XCTAssertTrue(urlConnections.count > 1 && urlConnections.count <= options.fallbackHosts!.count + 1)
        XCTAssertTrue(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io"))
        for connection in urlConnections.dropFirst() {
            XCTAssertTrue(NSRegularExpression.match(connection.absoluteString, pattern: "//[f-j].ably-realtime.com"))
        }
    }

    // RTN17d

    func skipped__test__097__Connection__Host_Fallback__should_use_an_alternative_host_when___hostUnreachable() {
        testUsesAlternativeHostOnResponse(.hostUnreachable, channelName: uniqueChannelName())
    }

    func skipped__test__098__Connection__Host_Fallback__should_use_an_alternative_host_when___requestTimeout_timeout__0_1_() {
        testUsesAlternativeHostOnResponse(.requestTimeout(timeout: 0.1), channelName: uniqueChannelName())
    }

    func skipped__test__099__Connection__Host_Fallback__should_use_an_alternative_host_when___hostInternalError_code__501_() {
        testUsesAlternativeHostOnResponse(.hostInternalError(code: 501), channelName: uniqueChannelName())
    }

    func test__100__Connection__Host_Fallback__should_move_to_disconnected_when_there_s_no_internet__with_NSPOSIXErrorDomain_with_code_57() throws {
        try testMovesToDisconnectedWithNetworkingError(NSError(domain: "NSPOSIXErrorDomain", code: 57, userInfo: [NSLocalizedDescriptionKey: "shouldn't matter"]))
    }

    func test__101__Connection__Host_Fallback__should_move_to_disconnected_when_there_s_no_internet__with_NSPOSIXErrorDomain_with_code_50() throws {
        try testMovesToDisconnectedWithNetworkingError(NSError(domain: "NSPOSIXErrorDomain", code: 50, userInfo: [NSLocalizedDescriptionKey: "shouldn't matter"]))
    }

    func test__102__Connection__Host_Fallback__should_move_to_disconnected_when_there_s_no_internet__with_any_kCFErrorDomainCFNetwork() throws {
        try testMovesToDisconnectedWithNetworkingError(NSError(domain: "kCFErrorDomainCFNetwork", code: 1337, userInfo: [NSLocalizedDescriptionKey: "shouldn't matter"]))
    }

    func test__090__Connection__Host_Fallback__should_not_use_an_alternative_host_when_the_client_receives_a_bad_request() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 1.0
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        let channel = client.channels.get(uniqueChannelName())

        transportFactory.fakeNetworkResponse = .host400BadRequest

        var urlConnections = [URL]()
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
        }

        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: "message") { _ in
                done()
            }
        }

        XCTAssertEqual(urlConnections.count, 1)
        XCTAssertTrue(NSRegularExpression.match(urlConnections[0].absoluteString, pattern: "//realtime.ably.io"))
    }

    // RTN17a
    func test__091__Connection__Host_Fallback__every_connection_is_first_attempted_to_the_primary_host_realtime_ably_io() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 1.0
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        client.channels.get(uniqueChannelName())

        transportFactory.fakeNetworkResponse = .hostUnreachable

        var urlConnections = [URL]()
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
            transportFactory.fakeNetworkResponse = nil
        }

        waitUntil(timeout: testTimeout) { done in
            // Unreachable and try a fallback
            client.connection.on { stateChange in
                // Timeout or 401 occurs because of the `xxxx:xxxx` key
                if stateChange.current == .disconnected || stateChange.current == .failed {
                    client.connection.off()
                    done()
                }
            }
            client.connect()
        }

        client.connect()

        waitUntil(timeout: testTimeout) { done in
            // 401 occurs because of the `xxxx:xxxx` key
            client.connection.once(.failed) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Error is nil"); done(); return
                }
                expect(error.message).to(contain("Invalid key"))
                done()
            }
        }

        XCTAssertEqual(urlConnections.count, 3)
        XCTAssertTrue(NSRegularExpression.match(urlConnections.at(0)?.absoluteString, pattern: "//realtime.ably.io"))
        XCTAssertTrue(NSRegularExpression.match(urlConnections.at(1)?.absoluteString, pattern: "//[a-e].ably-realtime.com"))
        XCTAssertTrue(NSRegularExpression.match(urlConnections.at(2)?.absoluteString, pattern: "//realtime.ably.io"))
    }

    // RTN17c
    func test__092__Connection__Host_Fallback__should_retry_hosts_in_random_order_after_checkin_if_an_internet_connection_is_available() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 5.0
        options.testOptions.shuffleArray = shuffleArrayInExpectedHostOrder
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        client.channels.get(uniqueChannelName())

        let testHttpExecutor = TestProxyHTTPExecutor(logger: .init(clientOptions: options))
        client.internal.rest.httpExecutor = testHttpExecutor

        transportFactory.fakeNetworkResponse = .hostUnreachable

        let hostPrefixes = Array("abcde")
        
        let extractHostname = { (url: URL) in
            NSRegularExpression.extract(url.absoluteString, pattern: "[\(hostPrefixes.first!)-\(hostPrefixes.last!)].ably-realtime.com")
        }
        
        var urls = [URL]()
        let expectedFallbackHosts = Array(expectedHostOrder.map { ARTDefault.fallbackHosts()[$0] })
        let allFallbackHostsTriedOfFailedExp = XCTestExpectation(description: "TestProxyTransport should spit 5 fallback hosts on networkConnectEvent")
        
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            DispatchQueue.main.async {
                urls.append(url)
            }
        }

        testHttpExecutor.setListenerAfterRequest { request in
            urls.append(request.url!)
        }

        waitUntil(timeout: testTimeout) { done in
            // wss://[a-e].ably-realtime.com: when a timeout occurs
            client.connection.once(.disconnected) { _ in
                done()
                allFallbackHostsTriedOfFailedExp.fulfill()
            }
            // wss://[a-e].ably-realtime.com: when a 401 occurs because of the `xxxx:xxxx` key
            client.connection.once(.failed) { _ in
                done()
                allFallbackHostsTriedOfFailedExp.fulfill()
            }
            client.connect()
        }
        
        wait(for: [allFallbackHostsTriedOfFailedExp], timeout: testTimeout.toTimeInterval())

        var resultFallbackHosts = [String]()
        var gotInternetIsUpCheck = false
        for url in urls {
            if NSRegularExpression.match(url.absoluteString, pattern: "//internet-up.ably-realtime.com/is-the-internet-up.txt") {
                gotInternetIsUpCheck = true
            } else if let fallbackHost = extractHostname(url) {
                if Optional(fallbackHost) == resultFallbackHosts.last {
                    continue
                }
                // Host changed; should've had an internet check before.
                XCTAssertTrue(gotInternetIsUpCheck)
                gotInternetIsUpCheck = false
                resultFallbackHosts.append(fallbackHost)
            }
        }

        XCTAssertEqual(resultFallbackHosts, expectedFallbackHosts)
    }

    // RTN17c
    func test__093__Connection__Host_Fallback__doesn_t_try_fallback_host_if_Internet_connection_check_fails() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.testOptions.realtimeRequestTimeout = 1.0
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        client.channels.get(uniqueChannelName())

        let internalLog = InternalLog(clientOptions: options)
        let mockHTTP = MockHTTP(logger: internalLog)
        let testHttpExecutor = TestProxyHTTPExecutor(http: mockHTTP, logger: internalLog)
        client.internal.rest.httpExecutor = testHttpExecutor

        transportFactory.fakeNetworkResponse = .hostUnreachable

        let extractHostname = { (url: URL) in
            NSRegularExpression.extract(url.absoluteString, pattern: "[a-e].ably-realtime.com")
        }

        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            if extractHostname(url) != nil {
                fail("shouldn't try fallback host after failed connectivity check")
            }
        }

        mockHTTP.setNetworkState(network: .hostInternalError(code: 500), forHost: "internet-up.ably-realtime.com")

        waitUntil(timeout: testTimeout) { done in
            // wss://[a-e].ably-realtime.com: when a timeout occurs
            client.connection.once(.disconnected) { _ in
                done()
            }
            // wss://[a-e].ably-realtime.com: when a 401 occurs because of the `xxxx:xxxx` key
            client.connection.once(.failed) { _ in
                done()
            }
            client.connect()
        }
    }

    func test__094__Connection__Host_Fallback__should_retry_custom_fallback_hosts_in_random_order_after_checkin_if_an_internet_connection_is_available() {
        let hostPrefixes = Array("fghij")
        let expectedFallbackHosts = Array(expectedHostOrder.map { "\(hostPrefixes[$0]).ably-realtime.com" })

        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.fallbackHosts = expectedFallbackHosts.sorted() // will be picked "randomly" as of expectedHostOrder
        options.testOptions.realtimeRequestTimeout = 5.0
        options.testOptions.shuffleArray = shuffleArrayInExpectedHostOrder
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        client.channels.get(uniqueChannelName())

        let testHttpExecutor = TestProxyHTTPExecutor(logger: .init(clientOptions: options))
        client.internal.rest.httpExecutor = testHttpExecutor

        transportFactory.fakeNetworkResponse = .hostUnreachable

        let extractHostname = { (url: URL) in
            NSRegularExpression.extract(url.absoluteString, pattern: "[\(hostPrefixes.first!)-\(hostPrefixes.last!)].ably-realtime.com")
        }
        
        var urls = [URL]()
        let allFallbackHostsTriedOfFailedExp = XCTestExpectation(description: "TestProxyTransport should spit 5 fallback hosts on networkConnectEvent")
        
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            DispatchQueue.main.async {
                urls.append(url)
            }
        }

        testHttpExecutor.setListenerAfterRequest { request in
            urls.append(request.url!)
        }

        waitUntil(timeout: testTimeout) { done in
            // wss://[a-e].ably-realtime.com: when a timeout occurs
            client.connection.once(.disconnected) { _ in
                done()
                allFallbackHostsTriedOfFailedExp.fulfill()
            }
            // wss://[a-e].ably-realtime.com: when a 401 occurs because of the `xxxx:xxxx` key
            client.connection.once(.failed) { _ in
                done()
                allFallbackHostsTriedOfFailedExp.fulfill()
            }
            client.connect()
        }
        
        wait(for: [allFallbackHostsTriedOfFailedExp], timeout: testTimeout.toTimeInterval())

        var resultFallbackHosts = [String]()
        var gotInternetIsUpCheck = false
        for url in urls {
            if NSRegularExpression.match(url.absoluteString, pattern: "//internet-up.ably-realtime.com/is-the-internet-up.txt") {
                gotInternetIsUpCheck = true
            } else if let fallbackHost = extractHostname(url) {
                if Optional(fallbackHost) == resultFallbackHosts.last {
                    continue
                }
                // Host changed; should've had an internet check before.
                XCTAssertTrue(gotInternetIsUpCheck)
                gotInternetIsUpCheck = false
                resultFallbackHosts.append(fallbackHost)
            }
        }

        XCTAssertEqual(resultFallbackHosts, expectedFallbackHosts)
    }

    func test__095__Connection__Host_Fallback__won_t_use_fallback_hosts_feature_if_an_empty_array_is_provided() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        options.fallbackHosts = []
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)
        let channel = client.channels.get(uniqueChannelName())

        let testHttpExecutor = TestProxyHTTPExecutor(logger: .init(clientOptions: options))
        client.internal.rest.httpExecutor = testHttpExecutor

        transportFactory.fakeNetworkResponse = .hostUnreachable

        var urlConnections = [URL]()
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
        }

        client.connect()
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: "message") { _ in
                done()
            }
        }

        XCTAssertEqual(urlConnections.count, 1)
    }

    // RTN17e
    func test__096__Connection__Host_Fallback__client_is_connected_to_a_fallback_host_endpoint_should_do_HTTP_requests_to_the_same_data_centre() {
        let options = ARTClientOptions(key: "xxxx:xxxx")
        options.autoConnect = false
        let transportFactory = TestProxyTransportFactory()
        options.testOptions.transportFactory = transportFactory
        let client = ARTRealtime(options: options)

        let testHttpExecutor = TestProxyHTTPExecutor(logger: .init(clientOptions: options))
        client.internal.rest.httpExecutor = testHttpExecutor

        transportFactory.fakeNetworkResponse = .hostUnreachable

        var urlConnections = [URL]()
        transportFactory.networkConnectEvent = { transport, url in
            if client.internal.transport !== transport {
                return
            }
            urlConnections.append(url)
            if urlConnections.count == 2 {
                transportFactory.fakeNetworkResponse = nil
                (client.internal.transport as! TestProxyTransport).simulateTransportSuccess()
            }
        }

        client.connect()
        // Because we're faking the CONNECTED state, we can't client.close() or it
        // will actually try to use the connection believing it's ready and throw an
        // exception because it's really not.

        expect(urlConnections).toEventually(haveCount(2), timeout: testTimeout)

        XCTAssertTrue(NSRegularExpression.match(urlConnections.at(1)?.absoluteString, pattern: "//[a-e].ably-realtime.com"))

        waitUntil(timeout: testTimeout) { done in
            client.time { _, _ in
                done()
            }
        }

        let timeRequestUrl = testHttpExecutor.requests.last!.url!
        XCTAssertEqual(timeRequestUrl.host, urlConnections.at(1)?.host)
    }

    // RTN19
    func test__010__Connection__attributes_within_ConnectionDetails_should_be_used_as_defaults() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        let realtime = AblyTests.newRealtime(options).client
        defer { realtime.close() }

        waitUntil(timeout: testTimeout) { done in
            realtime.connection.once(.connecting) { stateChange in
                XCTAssertNil(stateChange.reason)

                let transport = realtime.internal.transport as! TestProxyTransport
                transport.setBeforeIncomingMessageModifier { protocolMessage in
                    if protocolMessage.action == .connected {
                        protocolMessage.connectionDetails!.clientId = "john"
                        protocolMessage.connectionDetails!.connectionKey = "123"
                    }
                    return protocolMessage
                }
            }
            realtime.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)

                let transport = realtime.internal.transport as! TestProxyTransport
                let connectedProtocolMessage = transport.protocolMessagesReceived.filter { $0.action == .connected }[0]

                XCTAssertEqual(realtime.auth.clientId, connectedProtocolMessage.connectionDetails!.clientId)
                XCTAssertEqual(realtime.connection.key, connectedProtocolMessage.connectionDetails!.connectionKey)
                done()
            }
            realtime.connect()
        }

        let transport = realtime.internal.transport as! TestProxyTransport
        let connectedProtocolMessage = transport.protocolMessagesReceived.filter { $0.action == .connected }[0]
        XCTAssertEqual(realtime.auth.clientId, connectedProtocolMessage.connectionDetails!.clientId)
        XCTAssertEqual(realtime.connection.key, connectedProtocolMessage.connectionDetails!.connectionKey)
    }

    // RTN19a
    func skipped__test__103__Connection__Transport_disconnected_side_effects__should_resend_any_ProtocolMessage_that_is_awaiting_a_ACK_NACK() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())
        let transport = client.internal.transport as! TestProxyTransport

        waitUntil(timeout: testTimeout) { done in
            channel.attach { _ in done() }
        }

        waitUntil(timeout: testTimeout) { done in
            channel.publish(nil, data: "message") { error in
                XCTAssertNil(error)
                guard let newTransport = client.internal.transport as? TestProxyTransport else {
                    fail("Transport is nil"); done(); return
                }
                expect(newTransport).toNot(beIdenticalTo(transport))
                XCTAssertEqual(transport.protocolMessagesSent.filter { $0.action == .message }.count, 1)
                XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                XCTAssertEqual(newTransport.protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                XCTAssertEqual(newTransport.protocolMessagesSent.filter { $0.action == .message }.count, 1)
                done()
            }
            client.internal.onDisconnected()
        }
    }

    // RTN19b
    func skipped__test__104__Connection__Transport_disconnected_side_effects__should_resend_the_ATTACH_message_if_there_are_any_pending_channels() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not setup"); return
        }

        let channel = client.channels.get(uniqueChannelName())
        waitUntil(timeout: testTimeout) { done in
            transport.ignoreSends = true
            channel.attach { error in
                XCTAssertNil(error)
                guard let newTransport = client.internal.transport as? TestProxyTransport else {
                    fail("Transport is nil"); done(); return
                }
                XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                XCTAssertEqual(newTransport.protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                XCTAssertEqual(transport.protocolMessagesSent.filter { $0.action == .attach }.count, 0)
                XCTAssertEqual(transport.protocolMessagesSentIgnored.filter { $0.action == .attach }.count, 1)
                XCTAssertEqual(newTransport.protocolMessagesSent.filter { $0.action == .attach }.count, 1)
                expect(transport).toNot(beIdenticalTo(newTransport))
                done()
            }
            XCTAssertEqual(channel.state, ARTRealtimeChannelState.attaching)
            transport.ignoreSends = false
            AblyTests.queue.async {
                client.internal.onDisconnected()
            }
        }
    }

    // RTN19b
    func skipped__test__105__Connection__Transport_disconnected_side_effects__should_resent_the_DETACH_message_if_there_are_any_pending_channels() throws {
        let options = try AblyTests.commonAppSetup()
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())
        let transport = client.internal.transport as! TestProxyTransport

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { _ in done() }
        }

        waitUntil(timeout: testTimeout) { done in
            transport.ignoreSends = true
            channel.detach { error in
                XCTAssertNil(error)
                guard let newTransport = client.internal.transport as? TestProxyTransport else {
                    fail("Transport is nil"); done(); return
                }
                XCTAssertEqual(transport.protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                XCTAssertEqual(newTransport.protocolMessagesReceived.filter { $0.action == .connected }.count, 1)
                XCTAssertEqual(transport.protocolMessagesSent.filter { $0.action == .detach }.count, 0)
                XCTAssertEqual(transport.protocolMessagesSentIgnored.filter { $0.action == .detach }.count, 1)
                XCTAssertEqual(newTransport.protocolMessagesSent.filter { $0.action == .detach }.count, 1)
                done()
            }
            XCTAssertEqual(channel.state, ARTRealtimeChannelState.detaching)
            transport.ignoreSends = false
            client.internal.onDisconnected()
        }
    }

    // RTN20

    // RTN20a

    func beforeEach__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        internetConnectionNotAvailableTestsClient = ARTRealtime(options: options)
        internetConnectionNotAvailableTestsClient.internal.setReachabilityClass(TestReachability.self)
    }

    func afterEach__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available() {
        internetConnectionNotAvailableTestsClient.dispose()
        internetConnectionNotAvailableTestsClient.close()
    }

    func test__109__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available__when_CONNECTING() throws {
        try beforeEach__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available()

        waitUntil(timeout: testTimeout) { done in
            internetConnectionNotAvailableTestsClient.connection.on { stateChange in
                switch stateChange.current {
                case .connecting:
                    XCTAssertNil(stateChange.reason)
                    guard let reachability = internetConnectionNotAvailableTestsClient.internal.reachability as? TestReachability else {
                        fail("expected test reachability")
                        done(); return
                    }
                    XCTAssertEqual(reachability.host, internetConnectionNotAvailableTestsClient.internal.options.realtimeHost)
                    reachability.simulate(false)
                case .disconnected:
                    guard let reason = stateChange.reason else {
                        fail("expected error reason")
                        done(); return
                    }
                    XCTAssertEqual(reason.code, -1003)
                    done()
                default:
                    break
                }
            }
            internetConnectionNotAvailableTestsClient.connect()
        }

        afterEach__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available()
    }

    func test__110__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available__when_CONNECTED() throws {
        try beforeEach__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available()

        waitUntil(timeout: testTimeout) { done in
            internetConnectionNotAvailableTestsClient.connection.on { stateChange in
                switch stateChange.current {
                case .connected:
                    XCTAssertNil(stateChange.reason)
                    guard let reachability = internetConnectionNotAvailableTestsClient.internal.reachability as? TestReachability else {
                        fail("expected test reachability")
                        done(); return
                    }
                    XCTAssertEqual(reachability.host, internetConnectionNotAvailableTestsClient.internal.options.realtimeHost)
                    reachability.simulate(false)
                case .disconnected:
                    guard let reason = stateChange.reason else {
                        fail("expected error reason")
                        done(); return
                    }
                    XCTAssertEqual(reason.code, -1003)
                    done()
                default:
                    break
                }
            }
            internetConnectionNotAvailableTestsClient.connect()
        }

        afterEach__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_change_the_state_to_DISCONNECTED_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_no_longer_available()
    }

    // RTN20b
    func test__106__Connection__Operating_System_events_for_network_internet_connectivity_changes__should_immediately_attempt_to_connect_if_the_operating_system_indicates_that_the_underlying_internet_connection_is_now_available_when_DISCONNECTED_or_SUSPENDED() throws {
        var client: ARTRealtime!
        let options = try AblyTests.commonAppSetup()
        // Ensure it won't reconnect because of timeouts.
        options.disconnectedRetryTimeout = testTimeout.incremented(by: 10).toTimeInterval()
        options.suspendedRetryTimeout = testTimeout.incremented(by: 10).toTimeInterval()
        options.autoConnect = false
        client = ARTRealtime(options: options)
        client.internal.setReachabilityClass(TestReachability.self)
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.on { stateChange in
                switch stateChange.current {
                case .connecting:
                    if stateChange.previous == .disconnected {
                        client.internal.onSuspended()
                    } else if stateChange.previous == .suspended {
                        done()
                    }
                case .connected:
                    client.internal.onDisconnected()
                case .disconnected, .suspended:
                    guard let reachability = client.internal.reachability as? TestReachability else {
                        fail("expected test reachability")
                        done(); return
                    }
                    XCTAssertEqual(reachability.host, client.internal.options.realtimeHost)
                    reachability.simulate(true)
                default:
                    break
                }
            }
            client.connect()
        }
    }

    // RTN22
    func test__107__Connection__Operating_System_events_for_network_internet_connectivity_changes__Ably_can_request_that_a_connected_client_re_authenticates_by_sending_the_client_an_AUTH_ProtocolMessage() throws {
        let options = try AblyTests.commonAppSetup()
        options.autoConnect = false
        options.useTokenAuth = true
        options.testOptions.transportFactory = TestProxyTransportFactory()
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        
        let channelName = uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
            client.connect()
        }

        guard let initialConnectionId = client.connection.id else {
            fail("ConnectionId is nil"); return
        }

        guard let initialToken = client.auth.tokenDetails?.token else {
            fail("Initial token is nil"); return
        }

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.update) { stateChange in
                XCTAssertNil(stateChange.reason)
                XCTAssertNotEqual(initialToken, client.auth.tokenDetails?.token)
                done()
            }

            let authMessage = ARTProtocolMessage()
            authMessage.action = .auth
            client.internal.transport?.receive(authMessage)
        }

        XCTAssertEqual(client.connection.id, initialConnectionId)
        XCTAssertTrue(client.internal.transport === transport)

        let authMessages = transport.protocolMessagesSent.filter { $0.action == .auth }
        XCTAssertEqual(authMessages.count, 1)

        guard let authMessage = authMessages.first else {
            fail("Missing AUTH protocol message"); return
        }

        XCTAssertNotNil(authMessage.auth)

        guard (authMessage.auth?.accessToken) != nil else {
            fail("Missing accessToken from AUTH ProtocolMessage auth attribute"); return
        }

        let restOptions = try AblyTests.clientOptions(key: options.key!)
        restOptions.testOptions.channelNamePrefix = options.testOptions.channelNamePrefix
        let rest = ARTRest(options: restOptions)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            let expectedMessage = ARTMessage(name: "ios", data: "message1")

            channel.subscribe { message in
                XCTAssertEqual(message.name, expectedMessage.name)
                XCTAssertEqual(message.data as? String, expectedMessage.data as? String)
                partialDone()
            }

            rest.channels.get(channelName).publish([expectedMessage]) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        channel.off()
    }

    // RTN22a
    func test__108__Connection__Operating_System_events_for_network_internet_connectivity_changes__re_authenticate_and_resume_the_connection_when_the_client_is_forcibly_disconnected_following_a_DISCONNECTED_message_containing_an_error_code_greater_than_or_equal_to_40140_and_less_than_40150() throws {
        let options = try AblyTests.commonAppSetup()
        options.token = try getTestToken(key: options.key!, ttl: 5.0)
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }
        
        let channelName = uniqueChannelName()
        let channel = client.channels.get(channelName)

        waitUntil(timeout: testTimeout) { done in
            channel.attach { error in
                XCTAssertNil(error)
                done()
            }
        }

        guard let initialConnectionId = client.connection.id else {
            fail("ConnectionId is nil"); return
        }

        guard let initialToken = client.auth.tokenDetails?.token else {
            fail("Initial token is nil"); return
        }

        channel.once(.detached) { _ in
            fail("Should not detach channels")
        }

        var authorizeMethodCallCount = 0
        let hook = client.auth.internal.testSuite_injectIntoMethod(after: #selector(client.auth.internal._authorize(_:options:callback:))) {
            authorizeMethodCallCount += 1
        }
        defer { hook.remove() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.disconnected) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Error is nil"); done(); return
                }
                XCTAssertEqual(error.code, ARTErrorCode.tokenExpired.intValue)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                XCTAssertNotEqual(initialToken, client.auth.tokenDetails?.token)
                done()
            }
        }

        XCTAssertEqual(client.connection.id, initialConnectionId)
        XCTAssertEqual(authorizeMethodCallCount, 1)

        let restOptions = try AblyTests.clientOptions(key: options.key!)
        restOptions.testOptions.channelNamePrefix = options.testOptions.channelNamePrefix
        let rest = ARTRest(options: restOptions)

        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)
            let expectedMessage = ARTMessage(name: "ios", data: "message1")

            channel.subscribe { message in
                XCTAssertEqual(message.name, expectedMessage.name)
                XCTAssertEqual(message.data as? String, expectedMessage.data as? String)
                partialDone()
            }

            rest.channels.get(channelName).publish([expectedMessage]) { error in
                XCTAssertNil(error)
                partialDone()
            }
        }

        channel.off()
    }

    // RTN23a
    func test__011__Connection__should_disconnect_the_transport_when_no_activity_exist() throws {
        let options = try AblyTests.commonAppSetup()
        let realtimeRequestTimeout = 0.5
        options.testOptions.realtimeRequestTimeout = realtimeRequestTimeout
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        var expectedInactivityTimeout: TimeInterval?
        waitUntil(timeout: testTimeout) { done in
            let partialDone = AblyTests.splitDone(2, done: done)

            guard let transport = client.internal.transport as? TestProxyTransport else {
                fail("TestProxyTransport is not set"); partialDone(); return
            }

            var noActivityHasStartedAt: Date?
            transport.setBeforeIncomingMessageModifier { protocolMessage in
                if protocolMessage.action == .connected, let connectionDetails = protocolMessage.connectionDetails {
                    connectionDetails.setMaxIdleInterval(3)
                    expectedInactivityTimeout = connectionDetails.maxIdleInterval + realtimeRequestTimeout
                    // Force no activity
                    transport.ignoreWebSocket = true
                    noActivityHasStartedAt = Date()
                    transport.setBeforeIncomingMessageModifier(nil)
                    partialDone()
                }
                return protocolMessage
            }

            client.connection.on(.disconnected) { stateChange in
                let now = Date()

                XCTAssertEqual(stateChange.previous, ARTRealtimeConnectionState.connected)

                guard let noActivityHasStartedAt = noActivityHasStartedAt else {
                    fail("No activity date is missing"); partialDone(); return
                }
                guard let expectedInactivityTimeout = expectedInactivityTimeout else {
                    fail("Expected inactivity timeout is missing"); partialDone(); return
                }

                expect(now.timeIntervalSince(noActivityHasStartedAt)).to(beCloseTo(expectedInactivityTimeout, within: 1.0))

                guard let reason = stateChange.reason else {
                    fail("ConnectionStateChange reason is missing"); partialDone(); return
                }
                guard let errorReason = client.connection.errorReason else {
                    fail("Connection error is missing"); partialDone(); return
                }

                expect(reason.message).to(contain("Idle timer expired"))
                expect(errorReason.message).to(contain("Idle timer expired"))

                partialDone()
            }
        }

        XCTAssertEqual(expectedInactivityTimeout, 3.5)
        XCTAssertEqual(client.internal.maxIdleInterval, 3.0)
    }

    // RTN24
    func test__012__Connection__the_client_may_receive_a_CONNECTED_ProtocolMessage_from_Ably_at_any_point_and_should_emit_an_UPDATE_event() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
        }

        waitUntil(timeout: testTimeout) { done in
            let authMessage = ARTProtocolMessage()
            authMessage.action = ARTProtocolMessageAction.connected
            authMessage.error = ARTErrorInfo.create(withCode: 1234, message: "fabricated error")

            let listener = client.connection.once(.connected) { _ in
                fail("shouldn't emit CONNECTED")
            }
            client.connection.once(.update) { stateChange in
                XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.current, stateChange.previous)
                XCTAssertTrue(stateChange.reason === authMessage.error)
                delay(0.5) { // Give some time for the other listener to be triggered.
                    client.connection.off(listener)
                    done()
                }
            }

            client.internal.transport?.receive(authMessage)
        }
    }

    // RTN24
    func test__013__Connection__should_set_the_Connection_reason_attribute_based_on_the_Error_member_of_the_CONNECTED_ProtocolMessage() throws {
        let options = try AblyTests.commonAppSetup()
        options.useTokenAuth = true
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
        }

        guard let transport = client.internal.transport as? TestProxyTransport else {
            fail("TestProxyTransport is not set"); return
        }
        guard let originalConnectedMessage = transport.protocolMessagesReceived.filter({ $0.action == .connected }).first else {
            fail("First CONNECTED message not received"); return
        }

        client.connection.once(.connected) { _ in
            fail("Should not emit a Connected state")
        }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.update) { stateChange in
                guard let error = stateChange.reason else {
                    fail("Reason error is nil"); done(); return
                }
                XCTAssertEqual(error.code, 1234)
                XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.current, ARTRealtimeConnectionState.connected)
                XCTAssertEqual(stateChange.current, stateChange.previous)
                done()
            }

            let connectedMessageWithError = originalConnectedMessage
            connectedMessageWithError.error = ARTErrorInfo.create(withCode: 1234, message: "fabricated error")
            client.internal.transport?.receive(connectedMessageWithError)
        }

        XCTAssertNil(client.connection.errorReason)
    }

    // https://github.com/ably/ably-cocoa/issues/454
    func test__014__Connection__should_not_move_to_FAILED_if_received_DISCONNECT_with_an_error() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer {
            client.dispose()
            client.close()
        }

        expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)

        let protoMsg = ARTProtocolMessage()
        protoMsg.action = .disconnect
        protoMsg.error = ARTErrorInfo.create(withCode: 123, message: "test error")
        client.internal.transport?.receive(protoMsg)

        XCTAssertEqual(client.connection.state, ARTRealtimeConnectionState.disconnected)
        XCTAssertEqual(client.connection.errorReason, protoMsg.error)
    }

    // https://github.com/ably/wiki/issues/22
    func skipped__test__111__Connection__with_fixture_messages__should_encode_and_decode_fixture_messages_as_expected() throws {
        let options = try AblyTests.commonAppSetup()
        options.useBinaryProtocol = false
        let client = AblyTests.newRealtime(options).client
        defer { client.dispose(); client.close() }
        let channel = client.channels.get(uniqueChannelName())
        channel.attach()

        expect(channel.state).toEventually(equal(ARTRealtimeChannelState.attached), timeout: testTimeout)
        if channel.state != .attached {
            return
        }
        
        let messages = fixtures["messages"] as! [[String: Any]]
        
        for fixtureMessage in messages {
            var receivedMessage: ARTMessage?

            waitUntil(timeout: testTimeout) { done in
                channel.subscribe { message in
                    channel.unsubscribe()
                    receivedMessage = message
                    done()
                }

                let request = NSMutableURLRequest(url: URL(string: "/channels/\(channel.name)/messages")!)
                request.httpMethod = "POST"
                request.httpBody = try! JSONUtility.serialize(fixtureMessage)
                request.allHTTPHeaderFields = [
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                ]
                client.internal.rest.execute(request, withAuthOption: .on, completion: { _, _, err in
                    if let err = err {
                        fail("\(err)")
                    }
                })
            }

            guard let message = receivedMessage else {
                continue
            }

            expectDataToMatch(message, fixtureMessage)

            waitUntil(timeout: testTimeout) { done in
                channel.publish([message]) { err in
                    if let err = err {
                        fail("\(err)")
                        done()
                        return
                    }

                    let request = NSMutableURLRequest(url: URL(string: "/channels/\(channel.name)/messages?limit=1")!)
                    request.httpMethod = "GET"
                    request.allHTTPHeaderFields = ["Accept": "application/json"]
                    client.internal.rest.execute(request, withAuthOption: .on, completion: { _, data, err in
                        if let err = err {
                            fail("\(err)")
                            done()
                            return
                        }
                        let messages: [[String: Any]] = try! JSONUtility.jsonObject(data: data)
                        let persistedMessage = messages.first!
                        XCTAssertEqual(persistedMessage["data"] as? String, fixtureMessage["data"] as? String)
                        XCTAssertEqual(persistedMessage["encoding"] as? String, fixtureMessage["encoding"] as? String)
                        done()
                    })
                }
            }
        }
    }

    func skipped__test__112__Connection__with_fixture_messages__should_send_messages_through_raw_JSON_POST_and_retrieve_equal_messages_through_MsgPack_and_JSON() throws {
        try setupDependencies()
        let restPublishClient = ARTRest(options: jsonOptions)
        let realtimeSubscribeClientMsgPack = AblyTests.newRealtime(msgpackOptions).client
        let realtimeSubscribeClientJSON = AblyTests.newRealtime(jsonOptions).client
        defer {
            realtimeSubscribeClientMsgPack.close()
            realtimeSubscribeClientJSON.close()
        }

        let realtimeSubscribeChannelMsgPack = realtimeSubscribeClientMsgPack.channels.get(uniqueChannelName())
        let realtimeSubscribeChannelJSON = realtimeSubscribeClientJSON.channels.get(realtimeSubscribeChannelMsgPack.name)

        waitUntil(timeout: testTimeout) { done in
            let partlyDone = AblyTests.splitDone(2, done: done)
            realtimeSubscribeChannelMsgPack.attach { _ in partlyDone() }
            realtimeSubscribeChannelJSON.attach { _ in partlyDone() }
        }

        let messages = fixtures["messages"] as! [[String: Any]]
        
        for fixtureMessage in messages {
            waitUntil(timeout: testTimeout) { done in
                let partlyDone = AblyTests.splitDone(2, done: done)

                realtimeSubscribeChannelMsgPack.subscribe { message in
                    realtimeSubscribeChannelMsgPack.unsubscribe()
                    expectDataToMatch(message, fixtureMessage)
                    partlyDone()
                }

                realtimeSubscribeChannelJSON.subscribe { message in
                    realtimeSubscribeChannelJSON.unsubscribe()
                    expectDataToMatch(message, fixtureMessage)
                    partlyDone()
                }

                let request = NSMutableURLRequest(url: URL(string: "/channels/\(realtimeSubscribeChannelMsgPack.name)/messages")!)
                request.httpMethod = "POST"
                request.httpBody = try! JSONUtility.serialize(fixtureMessage)
                request.allHTTPHeaderFields = [
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                ]
                restPublishClient.internal.execute(request, withAuthOption: .on, completion: { _, _, err in
                    if let err = err {
                        fail("\(err)")
                    }
                })
            }
        }
    }

    func skipped__test__113__Connection__with_fixture_messages__should_send_messages_through_MsgPack_and_JSON_and_retrieve_equal_messages_through_raw_JSON_GET() throws {
        try setupDependencies()
        let restPublishClientMsgPack = ARTRest(options: msgpackOptions)
        let restPublishClientJSON = ARTRest(options: jsonOptions)
        let restRetrieveClient = ARTRest(options: jsonOptions)

        let restPublishChannelMsgPack = restPublishClientMsgPack.channels.get(uniqueChannelName())
        let restPublishChannelJSON = restPublishClientJSON.channels.get(restPublishChannelMsgPack.name)

        let messages = fixtures["messages"] as! [[String: Any]]
        
        for fixtureMessage in messages {
            var data: AnyObject
            if let expectedType = fixtureMessage["expectedType"] as? String, expectedType == "binary" {
                data = (fixtureMessage["expectedHexValue"] as! String).dataFromHexadecimalString()! as AnyObject
            } else {
                data = fixtureMessage["expectedValue"] as AnyObject
            }

            for restPublishChannel in [restPublishChannelMsgPack, restPublishChannelJSON] {
                waitUntil(timeout: testTimeout) { done in
                    restPublishChannel.publish("event", data: data) { err in
                        if let err = err {
                            fail("\(err)")
                            done()
                            return
                        }
                        done()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    let request = NSMutableURLRequest(url: URL(string: "/channels/\(restPublishChannel.name)/messages?limit=1")!)
                    request.httpMethod = "GET"
                    request.allHTTPHeaderFields = ["Accept": "application/json"]
                    restRetrieveClient.internal.execute(request, withAuthOption: .on, completion: { _, data, err in
                        if let err = err {
                            fail("\(err)")
                            done()
                            return
                        }
                        let messages: [[String: Any]] = try! JSONUtility.jsonObject(data: data)
                        let persistedMessage = messages.first!
                        
                        XCTAssertEqual(persistedMessage["data"] as? String, persistedMessage["data"] as? String)
                        XCTAssertEqual(persistedMessage["encoding"] as? String  , fixtureMessage["encoding"] as? String)
                        done()
                    })
                }
            }
        }
    }

    func test__015__Connection__should_abort_reconnection_with_new_token_if_the_server_has_requested_it_to_authorize_and_after_it_the_connection_has_been_closed() throws {
        let options = try AblyTests.commonAppSetup()
        let client = ARTRealtime(options: options)
        defer { client.dispose(); client.close() }

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.connected) { stateChange in
                XCTAssertNil(stateChange.reason)
                done()
            }
        }

        client.auth.internal.options.authCallback = { _, completion in
            getTestTokenDetails(ttl: 0.1) { tokenDetails, error in
                XCTAssertNil(error)
                guard let tokenDetails = tokenDetails else {
                    fail("TokenDetails is nil"); return
                }
                // Let the token expire
                delay(0.1) {
                    completion(tokenDetails.token as ARTTokenDetailsCompatible?, nil)
                }
            }
        }

        let authMessage = ARTProtocolMessage()
        authMessage.action = .auth
        client.internal.transport?.receive(authMessage)

        client.close()

        waitUntil(timeout: testTimeout) { done in
            client.connection.once(.failed) { _ in
                fail("Should not receive error 40142")
            }
            client.connection.once(.connected) { _ in
                fail("Should not connect")
            }
            client.connection.once(.closed) { _ in
                done()
            }
        }
    }
}
