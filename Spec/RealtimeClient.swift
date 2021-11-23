import Ably
import Quick
import Nimble
                private let query: ARTStatsQuery = {
                    let query = ARTStatsQuery()
                    query.unit = .minute
                    return query
                }()
            private let channelName = "test-message-size"
            private let presenceData = buildStringThatExceedMaxMessageSize()
            private let clientId = "testMessageSizeClientId"

class RealtimeClient: XCTestCase {

    func checkError(_ errorInfo: ARTErrorInfo?, withAlternative message: String) {
        if let error = errorInfo {
            XCTFail("\((error ).code): \(error.message)")
        }
        else if !message.isEmpty {
            XCTFail(message)
        }
    }

    func checkError(_ errorInfo: ARTErrorInfo?) {
        checkError(errorInfo, withAlternative: "")
    }

override class var defaultTestSuite : XCTestSuite {
    let _ = query
    let _ = channelName
    let _ = presenceData
    let _ = clientId

    return super.defaultTestSuite
}

        
            // G4
            func test__001__RealtimeClient__All_WebSocket_connections_should_include_the_current_API_version() {
                let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")
                waitUntil(timeout: testTimeout) { done in
                    channel.publish(nil, data: "message") { error in
                        expect(error).to(beNil())
                        let transport = client.internal.transport as! TestProxyTransport
                                                
                        // This test should not directly validate version against ARTDefault.version(), as
                        // ultimately the version header has been derived from that value.
                        expect(transport.lastUrl!.query).to(haveParam("v", withValue: "1.2"))
                        
                        done()
                    }
                }
            }

            // RTC1
            
                func test__013__RealtimeClient__options__should_support_the_same_options_as_the_Rest_client() {
                    let options = AblyTests.commonAppSetup() //Same as Rest
                    options.clientId = "client_string"

                    let client = ARTRealtime(options: options)
                    defer { client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .connecting, .closing, .closed:
                                break
                            case .failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            default:
                                expect(state).to(equal(ARTRealtimeConnectionState.connected))
                                done()
                                break
                            }
                        }
                    }
                }
                
                //RTC1a
                func test__014__RealtimeClient__options__should_echoMessages_option_be_true_by_default() {
                    let options = ARTClientOptions()
                    expect(options.echoMessages) == true
                }
                
                //RTC1b
                func test__015__RealtimeClient__options__should_autoConnect_option_be_true_by_default() {
                    let options = ARTClientOptions()
                    expect(options.autoConnect) == true
                }

                //RTC1c
                func test__016__RealtimeClient__options__should_attempt_to_recover_the_connection_state_if_recover_string_is_assigned() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"

                    // First connection
                    let client = ARTRealtime(options: options)
                    defer { client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .connected:
                                self.checkError(errorInfo)
                                expect(client.connection.recoveryKey).to(equal("\(client.connection.key ?? ""):\(client.connection.serial):\(client.internal.msgSerial)"), description: "recoveryKey wrong formed")
                                options.recover = client.connection.recoveryKey
                                done()
                            default:
                                break
                            }
                        }
                    }
                    client.connection.off()

                    // New connection
                    let newClient = ARTRealtime(options: options)
                    defer { newClient.close() }

                    waitUntil(timeout: testTimeout) { done in
                        newClient.connection.on { stateChange in
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .connected:
                                self.checkError(errorInfo)
                                done()
                            default:
                                break
                            }
                        }
                    }
                    newClient.connection.off()
                }

                //RTC1d
                func test__017__RealtimeClient__options__should_modify_the_realtime_endpoint_host_if_realtimeHost_is_assigned() {
                    let options = ARTClientOptions(key: "secret:key")
                    options.realtimeHost = "fake.ably.io"
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout.multiplied(by: 2)) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)
                        client.connection.once(.connecting) { _ in
                            guard let webSocketTransport = client.internal.transport as? ARTWebSocketTransport else {
                                fail("Transport should be of type ARTWebSocketTransport"); done()
                                return
                            }
                            expect(webSocketTransport.websocketURL).toNot(beNil())
                            expect(webSocketTransport.websocketURL?.host).to(equal("fake.ably.io"))
                            partialDone()
                        }
                        client.connection.once(.disconnected) { stateChange in
                            partialDone()
                        }
                        client.connect()
                    }
                }
                
                //RTC1e
                func test__018__RealtimeClient__options__should_modify_both_the_REST_and_realtime_endpoint_if_environment_string_is_assigned() {
                    let options = AblyTests.commonAppSetup()
                    
                    let oldRestHost = options.restHost
                    let oldRealtimeHost = options.realtimeHost

                    // Change REST and realtime endpoint hosts
                    options.environment = "test"
                    
                    expect(options.restHost).to(equal("test-rest.ably.io"))
                    expect(options.realtimeHost).to(equal("test-realtime.ably.io"))
                    // Extra care
                    expect(oldRestHost).to(equal("\(getEnvironment())-rest.ably.io"))
                    expect(oldRealtimeHost).to(equal("\(getEnvironment())-realtime.ably.io"))
                }
                
                //RTC1f
                func test__019__RealtimeClient__options__url_should_contains_transport_params() {
                    let options = AblyTests.commonAppSetup()
                    options.transportParams = [
                        "tpBool": .init(bool: true),
                        "tpInt": .init(number: .init(value: 12)),
                        "tpFloat": .init(number: .init(value: 12.12)),
                        "tpString": .init(string: "Lorem ipsum"),
                        "v": .init(string: "v12.34")
                    ]
                    
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout.multiplied(by: 2)) { done in
                        client.connection.once(.connecting) { _ in
                            guard let webSocketTransport = client.internal.transport as? ARTWebSocketTransport else {
                                fail("Transport should be of type ARTWebSocketTransport"); done()
                                return
                            }
                            let absoluteString = webSocketTransport.websocketURL?.absoluteString
                            
                            expect(webSocketTransport.websocketURL).toNot(beNil())
                            expect(absoluteString?.contains("tpBool=true")).to(beTrue())
                            expect(absoluteString?.contains("tpInt=12")).to(beTrue())
                            expect(absoluteString?.contains("tpFloat=12.12")).to(beTrue())
                            expect(absoluteString?.contains("tpString=Lorem%20ipsum")).to(beTrue())
                    
                            /**
                             Test that replacing query string default values in ARTClientOptions works properly
                             */
                            expect(absoluteString?.components(separatedBy: "v=").count).to(be(2))
                            
                            done()
                        }
                        client.connect()
                    }
                }

            // RTC2
            func test__002__RealtimeClient__should_have_access_to_the_underlying_Connection_object() {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                expect(client.connection).to(beAKindOf(ARTConnection.self))
            }

            // RTC3
            func test__003__RealtimeClient__should_provide_access_to_the_underlying_Channels_object() {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false

                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }

                client.channels.get("test").subscribe({ message in
                    // Attached
                })

                expect(client.channels.get("test")).toNot(beNil())
            }

            

                // RTC4
                func test__020__RealtimeClient__Auth_object__should_provide_access_to_the_Auth_object() {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    defer { client.close() }
                    expect(client.auth.internal.options.key).to(equal(options.key))
                }

                // RTC4a
                func test__021__RealtimeClient__Auth_object__clientId_may_be_populated_when_the_connection_is_established() {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    let client = ARTRealtime(options: options)
                    defer { client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .connected:
                                self.checkError(errorInfo)
                                expect(client.auth.clientId).to(equal(options.clientId))
                                done()
                            default:
                                break
                            }
                        }
                    }
                }

            

                // RTC5a
                func test__022__RealtimeClient__stats__should_present_an_async_interface() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    // Async
                    waitUntil(timeout: testTimeout) { done in
                        // Proxy from `client.internal.rest.stats`
                        expect {
                            try client.stats(query, callback: { paginated, error in
                                expect(paginated).toNot(beNil())
                                done()
                            })
                        }.toNot(throwError() { err in fail("\(err)"); done() })
                    }
                }

                // RTC5b
                func skipped__test__023__RealtimeClient__stats__should_accept_all_the_same_params_as_RestClient() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    var paginatedResult: ARTPaginatedResult<AnyObject>?
                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { _ in
                            done()
                        }
                    }

                    // Realtime
                    expect {
                        try client.stats(query, callback: { paginated, error in
                            if let e = error {
                                XCTFail(e.localizedDescription)
                            }
                            paginatedResult = paginated as! ARTPaginatedResult<AnyObject>?
                        })
                    }.toNot(throwError())
                    expect(paginatedResult).toEventuallyNot(beNil(), timeout: testTimeout)
                    if paginatedResult == nil {
                        return
                    }

                    // Rest
                    waitUntil(timeout: testTimeout) { done in
                        expect {
                            try client.internal.rest.stats(query, callback: { paginated, error in
                                defer { done() }
                                if let e = error {
                                    XCTFail(e.localizedDescription)
                                    return
                                }
                                guard let paginated = paginated else {
                                    XCTFail("both paginated and error are nil")
                                    return
                                } 
                                expect(paginated.items.count).to(equal(paginatedResult!.items.count))
                            })
                        }.toNot(throwError() { err in fail("\(err)"); done() })
                    }
                }

            
                // RTC6a
                func test__024__RealtimeClient__time__should_present_an_async_interface() {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    defer { client.close() }
                    // Async
                    waitUntil(timeout: testTimeout) { done in
                        // Proxy from `client.internal.rest.time`
                        client.time({ date, error in
                            expect(date).toNot(beNil())
                            done()
                        })
                    }
                }

            // RTC7
            func test__004__RealtimeClient__should_use_the_configured_timeouts_specified() {
                let options = AblyTests.commonAppSetup()
                options.suspendedRetryTimeout = 6.0

                let client = ARTRealtime(options: options)
                defer { client.close() }

                var start: NSDate?
                var endInterval: UInt?

                waitUntil(timeout: testTimeout.incremented(by: options.suspendedRetryTimeout)) { done in
                    client.connection.on { stateChange in
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .failed:
                            self.checkError(errorInfo, withAlternative: "Failed state")
                            done()
                        case .connecting:
                            if let start = start {
                                endInterval = UInt(start.timeIntervalSinceNow * -1)
                                done()
                            }
                        case .connected:
                            self.checkError(errorInfo)

                            if start == nil {
                                // Force
                                delay(0) {
                                    client.internal.onSuspended()
                                }
                            }
                        case .suspended:
                            start = NSDate()
                        default:
                            break
                        }
                    }
                }

                if let secs = endInterval {
                    expect(secs).to(beLessThanOrEqualTo(UInt(options.suspendedRetryTimeout)))
                }

                expect(client.internal.connectionStateTtl).to(equal(120 as TimeInterval /*seconds*/))
            }

            // RTC8
            

                // RTC8a
                func test__025__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__in_the_CONNECTED_state_and_auth_authorize_is_called__the_client_must_obtain_a_new_token__send_an_AUTH_ProtocolMessage_with_an_auth_attribute() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    guard let firstToken = client.auth.tokenDetails?.token else {
                        fail("Client has no token"); return
                    }

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); done(); return
                            }

                            let authMessages = transport.protocolMessagesSent.filter({ $0.action == .auth })
                            expect(authMessages).to(haveCount(1))

                            guard let authMessage = authMessages.first else {
                                fail("Missing AUTH protocol message"); done(); return
                            }

                            expect(authMessage.auth).toNot(beNil())

                            guard let accessToken = authMessage.auth?.accessToken else {
                                fail("Missing accessToken from AUTH ProtocolMessage auth attribute"); done(); return
                            }

                            expect(accessToken).toNot(equal(firstToken))
                            expect(tokenDetails.token).toNot(equal(firstToken))
                            expect(tokenDetails.token).to(equal(accessToken))

                            expect(client.internal.transport).to(beIdenticalTo(transport))

                            done()
                        }
                    }
                }

                // RTC8a1 - part 1
                func test__026__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_the_authentication_token_change_is_successful__then_the_client_should_receive_a_new_CONNECTED_ProtocolMessage() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.connected) { stateChange in
                            fail("Should not receive a CONNECTED event because the connection is already connected"); partialDone(); return
                        }

                        client.connection.once(.update) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connected))
                            expect(stateChange.reason).to(beNil())

                            guard let transport = client.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            let connectedMessages = transport.protocolMessagesReceived.filter{ $0.action == .connected }
                            expect(connectedMessages).to(haveCount(2))

                            guard let connectedAfterAuth = connectedMessages.last, let connectionDetailsAfterAuth = connectedAfterAuth.connectionDetails else {
                                fail("Missing CONNECTED protocol message after AUTH protocol message"); partialDone(); return
                            }

                            expect(client.auth.clientId).to(beNil())
                            expect(connectionDetailsAfterAuth.clientId).to(beNil())
                            expect(client.connection.key).to(equal(connectionDetailsAfterAuth.connectionKey))
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }
                            expect(tokenDetails.token).toNot(equal(testToken))
                            partialDone()
                        }

                        expect(client.connection.errorReason).to(beNil())
                    }

                    expect(client.auth.tokenDetails?.token).toNot(equal(testToken))
                }

                // RTC8a1 - part 2
                func test__027__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__performs_an_upgrade_of_capabilities_without_any_loss_of_continuity_or_connectivity_during_the_upgrade_process() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken(capability: "{\"test\":[\"subscribe\"]}")
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.failed) { stateChange in
                            guard let error = stateChange.reason else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("Channel denied access based on given capability"))
                            done()
                        }
                        channel.attach()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.update) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connected))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.connected) { _ in
                            fail("Already connected")
                        }
                        client.connection.once(.disconnected) { _ in
                            fail("Lost connectivity")
                        }
                        client.connection.once(.suspended) { _ in
                            fail("Lost continuity")
                        }
                        client.connection.once(.failed) { _ in
                            fail("Should not receive any failure")
                        }

                        let tokenParams = ARTTokenParams()
                        tokenParams.capability = "{\"*\":[\"*\"]}"

                        client.auth.authorize(tokenParams, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }
                            expect(tokenDetails.token).toNot(equal(testToken))
                            expect(tokenDetails.capability).to(equal(tokenParams.capability))
                            partialDone()
                        }
                    }

                    expect(client.auth.tokenDetails?.token).toNot(equal(testToken))

                    guard let transport = client.internal.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    expect(transport.protocolMessagesReceived.filter{ $0.action == .disconnected }).to(beEmpty())
                    // Should have one error: Channel denied access
                    expect(transport.protocolMessagesReceived.filter{ $0.action == .error }).to(haveCount(1))

                    // Retry Channel attach
                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.failed) { _ in
                            fail("Should not reach Failed state"); done(); return
                        }
                        channel.once(.attached) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        channel.attach()
                    }

                    expect(client.auth.tokenDetails?.token).toNot(equal(testToken))
                }

                // RTC8a1 - part 3
                func test__028__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_capabilities_are_downgraded__client_should_receive_an_ERROR_ProtocolMessage_with_a_channel_property() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        client.connect()
                        channel.attach() { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        channel.once(.failed) { stateChange in
                            guard let error = stateChange.reason else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(error).to(beIdenticalTo(channel.errorReason))
                            expect(error.code).to(equal(ARTErrorCode.operationNotPermittedWithProvidedCapability.intValue))

                            guard let transport = client.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }

                            let errorMessages = transport.protocolMessagesReceived.filter{ $0.action == .error }
                            expect(errorMessages).to(haveCount(1))

                            guard let errorMessage = errorMessages.first else {
                                fail("Missing ERROR protocol message"); partialDone(); return
                            }
                            expect(errorMessage.channel).to(contain("test"))
                            expect(errorMessage.error?.code).to(equal(error.code))
                            partialDone()
                        }

                        let tokenParams = ARTTokenParams()
                        tokenParams.capability = "{\"test\":[\"subscribe\"]}"

                        client.auth.authorize(tokenParams, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }
                            expect(tokenDetails.token).toNot(equal(testToken))
                            expect(tokenDetails.capability).to(equal(tokenParams.capability))
                            partialDone()
                        }
                    }

                    expect(client.auth.tokenDetails?.token).toNot(equal(testToken))
                }

                // RTC8a2
                func test__029__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_the_authentication_token_change_fails__client_should_receive_an_ERROR_ProtocolMessage_triggering_the_connection_to_transition_to_the_FAILED_state() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.clientId = "ios"
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    var connectionError: NSError?
                    var authError: NSError?

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.failed) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connected))
                            expect(stateChange.reason).toNot(beNil())
                            connectionError = stateChange.reason
                            partialDone()
                        }

                        let invalidToken = "xxxxxxxxxxxx"
                        let authOptions = ARTAuthOptions()
                        authOptions.authCallback = { tokenParams, completion in
                            completion(invalidToken as ARTTokenDetailsCompatible, nil)
                        }

                        client.auth.authorize(nil, options: authOptions) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(error.localizedDescription).to(contain("Invalid accessToken"))
                            expect(tokenDetails?.token).to(equal(invalidToken))
                            authError = error as NSError?
                            partialDone()
                        }
                    }

                    expect(authError).to(beIdenticalTo(connectionError))
                }

                func test__030__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__authorize_call_should_complete_with_an_error_if_the_request_fails() {
                    let options = AblyTests.clientOptions()
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let tokenParams = ARTTokenParams()
                        tokenParams.clientId = "john"

                        let simulatedError = NSError(domain: ARTAblyErrorDomain, code: 1234, userInfo: nil)

                        let authOptions = ARTAuthOptions()
                        authOptions.authCallback = { tokenParams, completion in
                            DispatchQueue.main.async {
                                completion(nil, simulatedError)
                            }
                        }

                        client.auth.authorize(tokenParams, options: authOptions) { tokenDetails, error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error as NSError).to(equal(simulatedError))
                            expect(tokenDetails).to(beNil())
                            done()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                    expect(client.auth.tokenDetails?.token).to(equal(testToken))
                }

                // RTC8a3
                func test__031__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__authorize_call_should_be_indicated_as_completed_with_the_new_token_or_error_only_once_realtime_has_responded_to_the_AUTH_with_either_a_CONNECTED_or_ERROR_respectively() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())

                            guard let transport = client.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); done(); return
                            }

                            expect(transport.protocolMessagesSent.filter({ $0.action == .auth })).to(haveCount(1))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .connected })).to(haveCount(2))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .error })).to(haveCount(0))
                            done()
                        }
                    }
                }

                // RTC8b
                func test__032__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_connection_is_CONNECTING__all_current_connection_attempts_should_be_halted__and_after_obtaining_a_new_token_the_library_should_immediately_initiate_a_connection_attempt_using_the_new_token() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    var connections = 0
                    let hook1 = TestProxyTransport.testSuite_injectIntoClassMethod(#selector(TestProxyTransport.connect(withToken:))) {
                        connections += 1
                    }
                    defer { hook1?.remove() }

                    var connectionsConnected = 0
                    let hook2 = client.connection.on(.connected) { _ in
                        connectionsConnected += 1
                    }
                    defer { client.connection.off(hook2) }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connecting) { stateChange in
                            expect(stateChange.reason).to(beNil())

                            let authOptions = ARTAuthOptions()
                            authOptions.key = AblyTests.commonAppSetup().key

                            client.auth.authorize(nil, options: authOptions) { tokenDetails, error in
                                expect(error).to(beNil())
                                guard let tokenDetails = tokenDetails else {
                                    fail("TokenDetails is nil"); done(); return
                                }
                                expect(tokenDetails.token).toNot(beNil())
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))

                                guard let transport = client.internal.transport as? TestProxyTransport else {
                                    fail("TestProxyTransport is not set"); done(); return
                                }
                                expect(transport.protocolMessagesReceived.filter({ $0.action == .connected })).to(haveCount(1))
                                done()
                            }
                        }
                        client.connect()
                    }

                    expect(connections) == 2
                    expect(connectionsConnected) == 1

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                }

                // RTC8b1 - part 1
                func test__033__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__authorize_call_should_complete_with_the_new_token_once_the_connection_has_moved_to_the_CONNECTED_state() {
                    let options = AblyTests.clientOptions()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        let authOptions = ARTAuthOptions()
                        authOptions.key = AblyTests.commonAppSetup().key

                        client.auth.authorize(nil, options: authOptions) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); done(); return
                            }
                            expect(tokenDetails.token).toNot(equal(testToken))
                            done()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                }

                // RTC8b1 - part 2
                func test__034__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__authorize_call_should_complete_with_an_error_if_the_connection_moves_to_the_FAILED_state() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let hook = client.auth.internal.testSuite_injectIntoMethod(after: #selector(client.auth.internal._authorize(_:options:callback:))) {
                        guard let transport = client.internal.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }
                        transport.simulateIncomingError()
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.failed) { stateChange in
                            guard let error = stateChange.reason else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(error.message).to(contain("Fail test"))
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect((error as NSError).code) == URLError.cancelled.rawValue
                            expect(client.connection.errorReason?.localizedDescription).to(contain("Fail test"))
                            expect(tokenDetails).to(beNil())
                            partialDone()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.failed))
                }

                // RTC8b1 - part 3
                func test__035__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__authorize_call_should_complete_with_an_error_if_the_connection_moves_to_the_SUSPENDED_state() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let hook = client.auth.internal.testSuite_injectIntoMethod(after: #selector(client.auth.internal._authorize(_:options:callback:))) {
                        client.internal.onSuspended()
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.suspended) { _ in
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect((error as NSError).code) == URLError.cancelled.rawValue
                            expect(tokenDetails).to(beNil())
                            partialDone()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.suspended))
                }

                // RTC8b1 - part 4
                func skipped__test__036__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__authorize_call_should_complete_with_an_error_if_the_connection_moves_to_the_CLOSED_state() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let hook = client.auth.internal.testSuite_injectIntoMethod(after: #selector(client.auth.internal._authorize(_:options:callback:))) {
                        delay(0) {
                            client.close()
                        }
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.closed) { _ in
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            guard let error = error else {
                                fail("Error is nil"); partialDone(); return
                            }
                            expect((error as NSError).code) == URLError.cancelled.rawValue
                            expect(tokenDetails).to(beNil())
                            partialDone()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.closed))
                }

                // RTC8c - part 1
                func test__037__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_the_connection_is_in_the_SUSPENDED_state_when_auth_authorize_is_called__after_obtaining_a_token_the_library_should_move_to_the_CONNECTING_state_and_initiate_a_connection_attempt_using_the_new_token() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.internal.onSuspended()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.suspended), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.connecting) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.suspended))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

                // RTC8c - part 2
                func test__038__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_the_connection_is_in_the_CLOSED_state_when_auth_authorize_is_called__after_obtaining_a_token_the_library_should_move_to_the_CONNECTING_state_and_initiate_a_connection_attempt_using_the_new_token() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.close()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.connecting) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.closed))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

                // RTC8c - part 3
                func test__039__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_the_connection_is_in_the_DISCONNECTED_state_when_auth_authorize_is_called__after_obtaining_a_token_the_library_should_move_to_the_CONNECTING_state_and_initiate_a_connection_attempt_using_the_new_token() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.internal.onDisconnected()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.disconnected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.connecting) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.disconnected))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

                // RTC8c - part 4
                func test__040__RealtimeClient__Auth_authorize_should_upgrade_the_connection_with_current_token__when_the_connection_is_in_the_FAILED_state_when_auth_authorize_is_called__after_obtaining_a_token_the_library_should_move_to_the_CONNECTING_state_and_initiate_a_connection_attempt_using_the_new_token() {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.internal.setTransport(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.internal.onError(AblyTests.newErrorProtocolMessage())
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.failed), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.connecting) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.failed))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.connected) { stateChange in
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.internal.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

            // FIXME Fix flaky presence tests and re-enable. See https://ably-real-time.slack.com/archives/C030C5YLY/p1623172436085700
            // https://github.com/ably/ably-cocoa/issues/577
            func skipped__test__005__RealtimeClient__background_behaviour() {
                waitUntil(timeout: testTimeout) { done in
                  URLSession.shared.dataTask(with: URL(string:"https://ably.io")!) { _ , _ , _  in
                        let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                        realtime.channels.get("foo").attach { error in
                            expect(error).to(beNil())
                            realtime.close()
                            done()
                        }
                    }.resume()
                }
            }

            func test__006__RealtimeClient__should_accept_acks_with_different_order() {
                let realtime = AblyTests.newRealtime(AblyTests.commonAppSetup())
                defer { realtime.dispose(); realtime.close() }
                let channel = realtime.channels.get("foo")
                waitUntil(timeout: testTimeout) { done in
                    channel.attach { error in
                        expect(error).to(beNil())
                        done()
                    }
                }
                guard let transport = realtime.internal.transport as? TestProxyTransport else {
                    fail("TestProxyTransport is not set"); return
                }

                waitUntil(timeout: testTimeout) { done in
                    transport.setListenerBeforeProcessingIncomingMessage({ pm in
                        if pm.action == .ack, let msgSerial = pm.msgSerial {
                            switch msgSerial.intValue {
                            case 0:
                                pm.msgSerial = 3
                            case 1:
                                pm.msgSerial = 2
                            case 2:
                                pm.msgSerial = 1
                            default:
                                pm.msgSerial = 0
                            }
                        }
                    })

                    let partialDone = AblyTests.splitDone(4, done: done)
                    channel.publish("test1", data: nil) { error in
                        expect(error).to(beNil())
                        partialDone()
                    }
                    channel.publish("test2", data: nil) { error in
                        expect(error).to(beNil())
                        partialDone()
                    }
                    channel.publish("test3", data: nil) { error in
                        expect(error).to(beNil())
                        partialDone()
                    }
                    channel.publish("test4", data: nil) { error in
                        expect(error).to(beNil())
                        partialDone()
                    }
                }
            }

            func test__007__RealtimeClient__transport_should_guarantee_the_incoming_message_order() {
                let realtime = ARTRealtime(options: AblyTests.commonAppSetup())
                defer { realtime.dispose(); realtime.close() }
                waitUntil(timeout: testTimeout) { done in
                    realtime.connection.on(.connected) { _ in
                        done()
                    }
                }
                guard let webSocketTransport = realtime.internal.transport as? ARTWebSocketTransport else {
                    fail("should be using a WebSocket transport"); return
                }

                var result: [Int] = []
                let expectedOrder = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30]

                waitUntil(timeout: testTimeout) { done in
                    let partialDone = AblyTests.splitDone(expectedOrder.count, done: done)

                    realtime.internal.testSuite_getArgument(from: NSSelectorFromString("ack:"), at: 0) { object in
                        guard let value = (object as? ARTProtocolMessage)?.msgSerial?.intValue else {
                            return
                        }
                        result.append(value)
                        partialDone()
                    }

                    for i in expectedOrder {
                        let message = ARTProtocolMessage()
                        message.action = .ack
                        message.msgSerial = i as NSNumber
                        webSocketTransport.webSocket(webSocketTransport.websocket!, didReceiveMessage: message)
                    }
                }

                expect(result).to(equal(expectedOrder))
            }
            
            func test__008__RealtimeClient__subscriber_should_receive_messages_in_the_same_order_in_which_they_have_been_sent() {
                let options = AblyTests.commonAppSetup()
                let realtime1 = ARTRealtime(options: options)
                let realtime2 = ARTRealtime(options: options)
                defer {
                    realtime1.dispose(); realtime1.close();
                    realtime2.dispose(); realtime2.close();
                }
                
                let subscribeChannel = realtime1.channels.get("testing")
                let sendChannel = realtime2.channels.get("testing")

                waitUntil(timeout: testTimeout) { done in
                    subscribeChannel.attach() { _ in
                        done()
                    }
                }

                let expectedResults = [Int](1...50)
                
                waitUntil(timeout: testTimeout) { done in
                    var index = 0
                    subscribeChannel.subscribe({ message in
                        let value = expectedResults[index]
                        let receivedValue = message.name
                        expect(receivedValue).to(equal(String(value)))
                        index += 1
                        if (receivedValue == String(describing: expectedResults.last!)) {
                            done()
                        }
                    })
                    for i in expectedResults {
                        sendChannel.publish(String(i), data: nil)
                    }
                }
            }

            // Issue https://github.com/ably/ably-cocoa/issues/640
            func test__009__RealtimeClient__should_dispatch_in_user_queue_when_removing_an_observer() {
                class AblyManager {
                    static let sharedClient = ARTRealtime(options: { $0.autoConnect = false; return $0 }(ARTClientOptions(key: "xxxx:xxxx")))
                }

                class Foo {
                    init() {
                        AblyManager.sharedClient.channels.get("foo").subscribe { _ in
                            // keep reference
                            self.update()
                        }
                    }
                    func update() {
                    }
                    deinit {
                        AblyManager.sharedClient.channels.get("foo").unsubscribe()
                    }
                }

                var foo: Foo? = Foo()
                expect(foo).toNot(beNil())
                foo = nil
                AblyManager.sharedClient.channels.get("foo").unsubscribe()
            }

            func test__010__RealtimeClient__should_never_register_any_connection_listeners_for_internal_use_with_the_public_EventEmitter() {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }

                client.connect()
                client.close() // Before it connects; this registers a listener on the internal event emitter.
                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connecting))
                client.connection.off()
                // If we didn't have a separate internal event emitter, the line above would unregister
                // the listener, and the next lines would fail, because we would never move to 
                // CLOSED, because we do that on the internal event listener registered when
                // we called close().
                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.connecting)) // Still connecting...
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.closed), timeout: testTimeout)
            }

            func test__011__RealtimeClient__should_never_register_any_message_and_channel_listeners_for_internal_use_with_the_public_EventEmitter() {
                let options = AblyTests.commonAppSetup()
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }

                let channel = client.channels.get("test")
                waitUntil(timeout: testTimeout) { done in
                    channel.attach { _ in
                        done()
                    }
                }
                if channel.state != .attached {
                    fail("Channel is not attached")
                    return
                }

                client.internal.onDisconnected()
                expect(client.connection.state).to(equal(.disconnected))

                // If we now send a message through the channel, it will be queued and the channel
                // should register a listener in the connection's _internal_ event emitter.
                // If we call client.connection.off(), reconnect, and never get the message ACK,
                // we probably weren't using the internal event emitter but the public one.

                client.connection.off()

                waitUntil(timeout: testTimeout) { done in
                    channel.publish("test", data: nil) { err in
                        expect(err).to(beNil())
                        done()
                    }
                    client.connect()
                }
            }
            
            func skipped__test__012__RealtimeClient__moves_to_DISCONNECTED_on_an_unexpected_normal_WebSocket_close() {
                let options = AblyTests.commonAppSetup()
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }
                
                var received = false
                client.channels.get("test").subscribe() { msg in
                    received = true
                }

                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                
                let ws = (client.internal.transport! as! ARTWebSocketTransport).websocket!
                ws.close(withCode: 1000, reason: "test")
                
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.disconnected), timeout: testTimeout)
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.connected), timeout: testTimeout)
                
                client.channels.get("test").publish(nil, data: "test")
                
                expect(received).toEventually(beTrue(), timeout: testTimeout)
            }
        
        // RSL1i
        
            
            func test__041__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_the_publish_and_indicate_an_error() {
                let options = AblyTests.commonAppSetup()
                let client = ARTRealtime(options: options)
                let channel = client.channels.get(channelName)
                let messages = buildMessagesThatExceedMaxMessageSize()
                
                waitUntil(timeout: testTimeout, action: { done in
                    // Wait for connected so that maxMessageSize is loaded from connection details
                    client.connection.once(.connected) { _ in
                        channel.publish(messages, callback: { err in
                            expect(err?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        })
                    }
                })
            }
            
            func test__042__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_also_presence_messages__enter_() {
                let options = AblyTests.commonAppSetup()
                options.clientId = clientId
                let client = ARTRealtime(options: options)
                let channel = client.channels.get(channelName)
                
                waitUntil(timeout: testTimeout, action: { done in
                    client.connection.once(.connected) { _ in
                        channel.presence.enter(presenceData, callback: { err in
                            expect(err?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        })
                    }
                })
            }
            
            func test__043__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_also_presence_messages__leave_() {
                let options = AblyTests.commonAppSetup()
                options.clientId = clientId
                let client = ARTRealtime(options: options)
                let channel = client.channels.get(channelName)
                
                waitUntil(timeout: testTimeout, action: { done in
                    client.connection.once(.connected) { _ in
                        channel.presence.leave(presenceData, callback: { err in
                            expect(err?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        })
                    }
                })
            }
            
            func test__044__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_also_presence_messages__update_() {
                let options = AblyTests.commonAppSetup()
                options.clientId = clientId
                let client = ARTRealtime(options: options)
                let channel = client.channels.get(channelName)
                
                waitUntil(timeout: testTimeout, action: { done in
                    client.connection.once(.connected) { _ in
                        channel.presence.update(presenceData, callback: { err in
                            expect(err?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        })
                    }
                })
            }
            
            func test__045__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_also_presence_messages__updateClient_() {
                let options = AblyTests.commonAppSetup()
                options.clientId = clientId
                let client = ARTRealtime(options: options)
                let channel = client.channels.get(channelName)
                
                waitUntil(timeout: testTimeout, action: { done in
                    client.connection.once(.connected) { _ in
                        channel.presence.updateClient(clientId, data: presenceData, callback: { err in
                            expect(err?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        })
                    }
                })
            }
            
            func test__046__If_the_total_size_of_message_s__exceeds_the_maxMessageSize__the_client_library_should_reject_also_presence_messages__leaveClient_() {
                let options = AblyTests.commonAppSetup()
                options.clientId = clientId
                let client = ARTRealtime(options: options)
                let channel = client.channels.get(channelName)
                
                waitUntil(timeout: testTimeout, action: { done in
                    client.connection.once(.connected) { _ in
                        channel.presence.leaveClient(clientId, data: presenceData, callback: { err in
                            expect(err?.code).to(equal(ARTErrorCode.maxMessageLengthExceeded.intValue))
                            done()
                        })
                    }
                })
            }
}
