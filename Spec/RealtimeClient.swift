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
