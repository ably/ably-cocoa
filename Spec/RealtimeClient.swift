//
//  RealtimeClient.swift
//  ably
//
//  Created by Ricardo Pereira on 26/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import Ably
import Quick
import Nimble

class RealtimeClient: QuickSpec {

    func checkError(errorInfo: ARTErrorInfo?, withAlternative message: String) {
        if let error = errorInfo {
            XCTFail("\(error.code): \(error.message)")
        }
        else if !message.isEmpty {
            XCTFail(message)
        }
    }

    func checkError(errorInfo: ARTErrorInfo?) {
        checkError(errorInfo, withAlternative: "")
    }

    override func spec() {
        describe("RealtimeClient") {
            // G4
            it("All WebSocket connections should include the current API version") {
                let client = AblyTests.newRealtime(AblyTests.commonAppSetup())
                defer { client.dispose(); client.close() }
                let channel = client.channels.get("test")
                waitUntil(timeout: testTimeout) { done in
                    channel.publish(nil, data: "message") { error in
                        expect(error).to(beNil())
                        let transport = client.transport as! TestProxyTransport
                        expect(transport.lastUrl!.query).to(haveParam("v", withValue: "0.9"))
                        done()
                    }
                }
            }

            // RTC1
            context("options") {
                it("should support the same options as the Rest client") {
                    let options = AblyTests.commonAppSetup() //Same as Rest
                    options.clientId = "client_string"

                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Connecting, .Closing, .Closed:
                                break
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            default:
                                expect(state).to(equal(ARTRealtimeConnectionState.Connected))
                                done()
                                break
                            }
                        }
                    }
                    client.close()
                }
                
                //RTC1a
                it("should echoMessages option be true by default") {
                    let options = ARTClientOptions()
                    expect(options.echoMessages) == true
                }
                
                //RTC1b
                it("should autoConnect option be true by default") {
                    let options = ARTClientOptions()
                    expect(options.autoConnect) == true
                }

                //RTC1c
                it("should attempt to recover the connection state if recover string is assigned") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"

                    // First connection
                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                self.checkError(errorInfo)
                                expect(client.connection.recoveryKey).to(equal("\(client.connection.key ?? ""):\(client.connection.serial)"), description: "recoveryKey wrong formed")
                                options.recover = client.connection.recoveryKey
                                done()
                            default:
                                break
                            }
                        }
                    }

                    // New connection
                    let newClient = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        newClient.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                self.checkError(errorInfo)
                                done()
                            default:
                                break
                            }
                        }
                    }
                    newClient.close()
                    client.close()
                }

                //RTC1d
                it("should modify the realtime endpoint host if realtimeHost is assigned") {
                    let options = ARTClientOptions(key: "secret:key")
                    options.realtimeHost = "fake.ably.io"
                    options.autoConnect = false
                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connecting) { _ in
                            guard let webSocketTransport = client.transport as? ARTWebSocketTransport else {
                                fail("Transport should be of type ARTWebSocketTransport"); done()
                                return
                            }
                            expect(webSocketTransport.websocketURL).toNot(beNil())
                            expect(webSocketTransport.websocketURL?.host).to(equal("fake.ably.io"))
                            done()
                        }
                        client.connect()
                    }
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Disconnected), timeout: testTimeout)
                }
                
                //RTC1e
                it("should modify both the REST and realtime endpoint if environment string is assigned") {
                    let options = AblyTests.commonAppSetup()
                    
                    let oldRestHost = options.restHost
                    let oldRealtimeHost = options.realtimeHost

                    // Change REST and realtime endpoint hosts
                    options.environment = "test"
                    
                    expect(options.restHost).to(equal("test-rest.ably.io"))
                    expect(options.realtimeHost).to(equal("test-realtime.ably.io"))
                    // Extra care
                    expect(oldRestHost).to(equal("sandbox-rest.ably.io"))
                    expect(oldRealtimeHost).to(equal("sandbox-realtime.ably.io"))
                }
            }

            // RTC2
            it("should have access to the underlying Connection object") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                expect(client.connection).to(beAKindOf(ARTConnection))
            }

            // RTC3
            it("should provide access to the underlying Channels object") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false

                let client = ARTRealtime(options: options)

                client.channels.get("test").subscribe({ message in
                    // Attached
                })

                expect(client.channels.get("test")).toNot(beNil())
                client.close()
            }

            context("Auth object") {

                // RTC4
                it("should provide access to the Auth object") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)

                    expect(client.auth.options.key).to(equal(options.key))
                    client.close()
                }

                // RTC4a
                it("clientId may be populated when the connection is established") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    let client = ARTRealtime(options: options)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.on { stateChange in
                            let stateChange = stateChange!
                            let state = stateChange.current
                            let errorInfo = stateChange.reason
                            switch state {
                            case .Failed:
                                self.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                self.checkError(errorInfo)
                                expect(client.auth.clientId).to(equal(options.clientId))
                                done()
                            default:
                                break
                            }
                        }
                    }
                    client.close()
                }
            }

            context("stats") {
                let query = ARTStatsQuery()
                query.unit = .Minute

                // RTC5a
                it("should present an async interface") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    // Async
                    waitUntil(timeout: testTimeout) { done in
                        // Proxy from `client.rest.stats`
                        try! client.stats(query, callback: { paginated, error in
                            expect(paginated).toNot(beNil())
                            done()
                        })
                    }
                    client.close()
                }

                // RTC5b
                it("should accept all the same params as RestClient") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    var paginatedResult: ARTPaginatedResult?

                    // Realtime
                    try! client.stats(query, callback: { paginated, error in
                        if let e = error {
                            XCTFail(e.description)
                        }
                        paginatedResult = paginated
                    })
                    expect(paginatedResult).toEventuallyNot(beNil(), timeout: testTimeout)
                    if paginatedResult == nil {
                        return
                    }

                    // Rest
                    waitUntil(timeout: testTimeout) { done in
                        try! client.rest.stats(query, callback: { paginated, error in
                            defer { done() }
                            if let e = error {
                                XCTFail(e.description)
                                return
                            }
                            guard let paginated = paginated else {
                                XCTFail("both paginated and error are nil")
                                return
                            } 
                            expect(paginated.items.count).to(equal(paginatedResult!.items.count))
                        })
                    }
                    client.close()
                }
            }

            context("time") {
                // RTC6a
                it("should present an async interface") {
                    let client = ARTRealtime(options: AblyTests.commonAppSetup())
                    // Async
                    waitUntil(timeout: testTimeout) { done in
                        // Proxy from `client.rest.time`
                        client.time({ date, error in
                            expect(date).toNot(beNil())
                            done()
                        })
                    }
                    client.close()
                }
            }

            // RTC7
            it("should use the configured timeouts specified") {
                let options = AblyTests.commonAppSetup()
                options.suspendedRetryTimeout = 6.0

                let client = ARTRealtime(options: options)

                var start: NSDate?
                var endInterval: UInt?

                waitUntil(timeout: testTimeout + options.suspendedRetryTimeout) { done in
                    client.connection.on { stateChange in
                        let stateChange = stateChange!
                        let state = stateChange.current
                        let errorInfo = stateChange.reason
                        switch state {
                        case .Failed:
                            self.checkError(errorInfo, withAlternative: "Failed state")
                            done()
                        case .Connecting:
                            if let start = start {
                                endInterval = UInt(start.timeIntervalSinceNow * -1)
                                done()
                            }
                        case .Connected:
                            self.checkError(errorInfo)

                            if start == nil {
                                // Force
                                client.onSuspended()
                            }
                        case .Suspended:
                            start = NSDate()
                        default:
                            break
                        }
                    }
                }
                client.close()

                if let secs = endInterval {
                    expect(secs).to(beLessThanOrEqualTo(UInt(options.suspendedRetryTimeout)))
                }
            }

            // RTC8
            context("Auth#authorize should upgrade the connection with current token") {

                // RTC8a
                it("in the CONNECTED state and auth#authorize is called, the client must obtain a new token, send an AUTH ProtocolMessage with an auth attribute") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    guard let firstToken = client.auth.tokenDetails?.token else {
                        fail("Client has no token"); return
                    }

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); done(); return
                            }

                            let authMessages = transport.protocolMessagesSent.filter({ $0.action == .Auth })
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
                            done()
                        }
                    }
                }

                // RTC8a1 - part 1
                it("when the authentication token change is successful, then the client should receive a new CONNECTED ProtocolMessage") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.Connected) { stateChange in
                            fail("Should not receive a CONNECTED event because the connection is already connected"); partialDone(); return
                        }

                        client.connection.once(.Update) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(stateChange.reason).to(beNil())

                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            let connectedMessages = transport.protocolMessagesReceived.filter{ $0.action == .Connected }
                            expect(connectedMessages).to(haveCount(2))

                            guard let connectedAfterAuth = connectedMessages.last, connectionDetailsAfterAuth = connectedAfterAuth.connectionDetails else {
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
                it("performs an upgrade of capabilities without any loss of continuity or connectivity during the upgrade process") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken(capability: "{\"test\":[\"subscribe\"]}")
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let channel = client.channels.get("foo")
                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.Failed) { error in
                            guard let error = error else {
                                fail("Error is nil"); done(); return
                            }
                            expect(error.message).to(contain("Channel denied access based on given capability"))
                            done()
                        }
                        channel.attach()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.Update) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.Connected) { _ in
                            fail("Already connected")
                        }
                        client.connection.once(.Disconnected) { _ in
                            fail("Lost connectivity")
                        }
                        client.connection.once(.Suspended) { _ in
                            fail("Lost continuity")
                        }
                        client.connection.once(.Failed) { _ in
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

                    guard let transport = client.transport as? TestProxyTransport else {
                        fail("TestProxyTransport is not set"); return
                    }

                    expect(transport.protocolMessagesReceived.filter{ $0.action == .Disconnected }).to(beEmpty())
                    // Should have one error: Channel denied access
                    expect(transport.protocolMessagesReceived.filter{ $0.action == .Error }).to(haveCount(1))

                    // Retry Channel attach
                    waitUntil(timeout: testTimeout) { done in
                        channel.once(.Failed) { error in
                            fail("Should not reach Failed state"); done(); return
                        }
                        channel.once(.Attached) { error in
                            expect(error).to(beNil())
                            done()
                        }
                        channel.attach()
                    }

                    expect(client.auth.tokenDetails?.token).toNot(equal(testToken))
                }

                // RTC8a1 - part 3
                it("when capabilities are downgraded, client should receive an ERROR ProtocolMessage with a channel property") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

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

                        channel.once(.Failed) { error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(error).to(beIdenticalTo(channel.errorReason))
                            expect(error.code).to(equal(40160))

                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }

                            let errorMessages = transport.protocolMessagesReceived.filter{ $0.action == .Error }
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
                it("when the authentication token change fails, client should receive an ERROR ProtocolMessage triggering the connection to transition to the FAILED state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.clientId = "ios"
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    var connectionError: NSError?
                    var authError: NSError?

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.Failed) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(stateChange.reason).toNot(beNil())
                            connectionError = stateChange.reason
                            partialDone()
                        }

                        let authOptions = ARTAuthOptions()
                        authOptions.authCallback = { tokenParams, completion in
                            let invalidToken = "xxxxxxxxxxxx"
                            completion(invalidToken, nil)
                        }

                        client.auth.authorize(nil, options: authOptions) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(error.description).to(contain("Invalid accessToken"))
                            expect(tokenDetails).to(beNil())
                            authError = error
                            partialDone()
                        }
                    }

                    expect(authError).to(beIdenticalTo(connectionError))
                }

                it("authorize call should complete with an error if the request fails") {
                    let options = AblyTests.clientOptions()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let tokenParams = ARTTokenParams()
                        tokenParams.clientId = "john"

                        let authOptions = ARTAuthOptions()
                        authOptions.authCallback = { tokenParams, completion in
                            completion(getTestTokenDetails(clientId: "tester"), nil)
                        }

                        client.auth.authorize(tokenParams, options: authOptions) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); done(); return
                            }
                            expect(error.code).to(equal(40102))
                            expect(error.description).to(contain("incompatible credentials"))
                            expect(tokenDetails).to(beNil())
                            done()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                    expect(client.auth.tokenDetails!.token).to(equal(testToken))
                }

                // RTC8a3
                it("authorize call should be indicated as completed with the new token or error only once realtime has responded to the AUTH with either a CONNECTED or ERROR respectively") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            expect(tokenDetails).toNot(beNil())

                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); done(); return
                            }

                            expect(transport.protocolMessagesSent.filter({ $0.action == .Auth })).to(haveCount(1))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .Connected })).to(haveCount(2))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .Error })).to(haveCount(0))
                            done()
                        }
                    }
                }

                // RTC8b
                it("when connection is CONNECTING, all current connection attempts should be halted, and after obtaining a new token the library should immediately initiate a connection attempt using the new token") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    var connections = 0
                    let hook1 = TestProxyTransport.testSuite_injectIntoClassMethod(#selector(TestProxyTransport.connectWithToken(_:))) {
                        connections += 1
                    }
                    defer { hook1?.remove() }

                    var connectionsOpened = 0
                    let hook2 = TestProxyTransport.testSuite_injectIntoClassMethod(#selector(TestProxyTransport.webSocketDidOpen)) {
                        connectionsOpened += 1
                    }
                    defer { hook2?.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connecting) { stateChange in
                            expect(stateChange?.reason).to(beNil())

                            let authOptions = ARTAuthOptions()
                            authOptions.key = AblyTests.commonAppSetup().key

                            client.auth.authorize(nil, options: authOptions) { tokenDetails, error in
                                expect(error).to(beNil())
                                guard let tokenDetails = tokenDetails else {
                                    fail("TokenDetails is nil"); done(); return
                                }
                                expect(tokenDetails.token).toNot(beNil())
                                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))

                                guard let transport = client.transport as? TestProxyTransport else {
                                    fail("TestProxyTransport is not set"); done(); return
                                }
                                expect(transport.protocolMessagesReceived.filter({ $0.action == .Connected })).to(haveCount(1))
                                done()
                            }
                        }
                        client.connect()
                    }

                    expect(connections) == 2
                    expect(connectionsOpened) == 1

                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Connected), timeout: testTimeout)
                }

                // RTC8b1 - part 1
                it("authorize call should complete with the new token once the connection has moved to the CONNECTED state") {
                    let options = AblyTests.clientOptions()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

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

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                }

                // RTC8b1 - part 2
                it("authorize call should complete with an error if the connection moves to the FAILED state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let hook = client.auth.testSuite_injectIntoMethodAfter(#selector(client.auth.authorize(_:options:callback:))) {
                        guard let transport = client.transport as? TestProxyTransport else {
                            fail("TestProxyTransport is not set"); return
                        }
                        transport.simulateIncomingError()
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.Failed) { stateChange in
                            guard let error = stateChange?.reason else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(error.message).to(contain("Fail test"))
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(error.description).to(contain("Fail test"))
                            expect(tokenDetails).to(beNil())
                            partialDone()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Failed))
                }

                // RTC8b1 - part 3
                it("authorize call should complete with an error if the connection moves to the SUSPENDED state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let hook = client.auth.testSuite_injectIntoMethodAfter(#selector(client.auth.authorize(_:options:callback:))) {
                        client.onSuspended()
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.Suspended) { _ in
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(UInt(error.code)) == ARTState.AuthorizationFailed.rawValue
                            expect(tokenDetails).to(beNil())
                            partialDone()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Suspended))
                }

                // RTC8b1 - part 4
                it("authorize call should complete with an error if the connection moves to the CLOSED state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    options.useTokenAuth = true
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    let hook = client.auth.testSuite_injectIntoMethodAfter(#selector(client.auth.authorize(_:options:callback:))) {
                        client.close()
                    }
                    defer { hook.remove() }

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(2, done: done)

                        client.connection.once(.Closed) { _ in
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            guard let error = error else {
                                fail("ErrorInfo is nil"); partialDone(); return
                            }
                            expect(UInt(error.code)) == ARTState.AuthorizationFailed.rawValue
                            expect(tokenDetails).to(beNil())
                            partialDone()
                        }
                    }

                    expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Closed))
                }

                // RTC8c - part 1
                it("when the connection is in the SUSPENDED state when auth#authorize is called, after obtaining a token the library should move to the CONNECTING state and initiate a connection attempt using the new token") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.onSuspended()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Suspended), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.Connecting) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Suspended))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.Connected) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .Auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .Connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

                // RTC8c - part 2
                it("when the connection is in the CLOSED state when auth#authorize is called, after obtaining a token the library should move to the CONNECTING state and initiate a connection attempt using the new token") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.close()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Closed), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.Connecting) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Closed))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.Connected) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .Auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .Connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

                // RTC8c - part 3
                it("when the connection is in the DISCONNECTED state when auth#authorize is called, after obtaining a token the library should move to the CONNECTING state and initiate a connection attempt using the new token") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.onDisconnected()
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Disconnected), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.Connecting) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Disconnected))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.Connected) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .Auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .Connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

                // RTC8c - part 4
                it("when the connection is in the FAILED state when auth#authorize is called, after obtaining a token the library should move to the CONNECTING state and initiate a connection attempt using the new token") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let testToken = getTestToken()
                    options.token = testToken
                    let client = ARTRealtime(options: options)
                    defer { client.dispose(); client.close() }
                    client.setTransportClass(TestProxyTransport.self)

                    waitUntil(timeout: testTimeout) { done in
                        client.connection.once(.Connected) { stateChange in
                            expect(stateChange?.reason).to(beNil())
                            done()
                        }
                        client.connect()
                    }

                    client.onError(AblyTests.newErrorProtocolMessage())
                    expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Failed), timeout: testTimeout)

                    waitUntil(timeout: testTimeout) { done in
                        let partialDone = AblyTests.splitDone(3, done: done)

                        client.connection.once(.Connecting) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Failed))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.connection.once(.Connected) { stateChange in
                            guard let stateChange = stateChange else {
                                fail("ConnectionStateChange is nil"); partialDone(); return
                            }
                            expect(stateChange.previous).to(equal(ARTRealtimeConnectionState.Connecting))
                            expect(stateChange.reason).to(beNil())
                            partialDone()
                        }

                        client.auth.authorize(nil, options: nil) { tokenDetails, error in
                            expect(error).to(beNil())
                            guard let tokenDetails = tokenDetails else {
                                fail("TokenDetails is nil"); partialDone(); return
                            }

                            expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connected))
                            expect(tokenDetails.token).toNot(equal(testToken))

                            guard let transport = client.transport as? TestProxyTransport else {
                                fail("TestProxyTransport is not set"); partialDone(); return
                            }
                            expect(transport.protocolMessagesSent.filter({ $0.action == .Auth })).to(haveCount(0))
                            expect(transport.protocolMessagesReceived.filter({ $0.action == .Connected })).to(haveCount(1)) //New transport
                            partialDone()
                        }
                    }
                }

            }

            it("should never register any connection listeners for internal use with the public EventEmitter") {
                let options = AblyTests.commonAppSetup()
                options.autoConnect = false
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }

                client.connect()
                client.close() // Before it connects; this registers a listener on the internal event emitter.
                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connecting))
                client.connection.off()
                // If we didn't have a separate internal event emitter, the line above would unregister
                // the listener, and the next lines would fail, because we would never move to 
                // CLOSED, because we do that on the internal event listener registered when
                // we called close().
                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Connecting)) // Still connecting...
                expect(client.connection.state).toEventually(equal(ARTRealtimeConnectionState.Closed), timeout: testTimeout)
            }

            it("should never register any message and channel listeners for internal use with the public EventEmitter") {
                let options = AblyTests.commonAppSetup()
                let client = ARTRealtime(options: options)
                defer { client.dispose(); client.close() }

                let channel = client.channels.get("test")
                waitUntil(timeout: testTimeout) { done in
                    channel.attach { _ in
                        done()
                    }
                }
                if channel.state != .Attached {
                    return
                }

                client.onDisconnected()
                expect(client.connection.state).to(equal(ARTRealtimeConnectionState.Disconnected))

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
        }
    }
}
