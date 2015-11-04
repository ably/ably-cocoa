//
//  RealtimeClient.connection.swift
//  ably
//
//  Created by Ricardo Pereira on 03/11/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

import Quick
import Nimble

@testable import ably
@testable import ably.Private

/// A Nimble matcher that succeeds when a param exists.
public func haveParam(expectedValue: String) -> NonNilMatcherFunc<String> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "param <\(expectedValue)> exists"
        if let actualValue = try actualExpression.evaluate() {
            let queryItems = actualValue.componentsSeparatedByString("&")
            for item in queryItems {
                let param = item.componentsSeparatedByString("=")
                if param[0] == expectedValue {
                    return true
                }
            }
        }
        return false
    }
}

class RealtimeClientConnection: QuickSpec {

    override func spec() {
        describe("Connection") {
            // RTN1
            it("should support additional transports") {
                // Only uses websocket transport.
            }

            // RTN2
            context("url") {
                it("should connect to the default host") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(MockTransport.self)
                    client.connect()

                    if let transport = client.transport as? MockTransport, let url = transport.lastUrl {
                        expect(url.host).to(equal("sandbox-realtime.ably.io"))
                    }
                    else {
                        XCTFail("MockTransport isn't working")
                    }
                }

                it("should connect with query string params") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(MockTransport.self)
                    client.connect()

                    waitUntil(timeout: 25.0) { done in
                        client.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Failed:
                                AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                if let transport = client.transport as? MockTransport, let query = transport.lastUrl?.query {
                                    expect(query).to(haveParam("key"))
                                    expect(query).to(haveParam("echo"))
                                    expect(query).to(haveParam("format"))
                                }
                                else {
                                    XCTFail("MockTransport isn't working")
                                }
                                done()
                                break
                            default:
                                break
                            }
                        }
                    }
                }

                it("should connect with query string params including clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "client_string"
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    client.setTransportClass(MockTransport.self)
                    client.connect()

                    waitUntil(timeout: 25.0) { done in
                        client.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Failed:
                                AblyTests.checkError(errorInfo, withAlternative: "Failed state")
                                done()
                            case .Connected:
                                if let transport = client.transport as? MockTransport, let query = transport.lastUrl?.query {
                                    expect(query).to(haveParam("access_token"))
                                    expect(query).to(haveParam("echo"))
                                    expect(query).to(haveParam("format"))
                                    expect(query).to(haveParam("client_id"))
                                }
                                else {
                                    XCTFail("MockTransport isn't working")
                                }
                                done()
                                break
                            default:
                                break
                            }
                        }
                    }
                }
            }

            // RTN3
            it("should connect automatically") {
                let options = AblyTests.commonAppSetup()
                var connected = false

                // The only way to control this functionality is with the options flag
                options.autoConnect = true
                ARTRealtime(options: options).eventEmitter.on { state, errorInfo in
                    switch state {
                    case .Connected:
                        connected = true
                    default:
                        break
                    }
                }
                expect(connected).toEventually(beTrue(), timeout: 10.0, description: "Can't connect automatically")
            }

            // RTN4
            context("event emitter") {
                // RTN4a
                it("should emit events for state changes") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false

                    let client = ARTRealtime(options: options)
                    let connection = client.connection()
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: 25.0) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Initialized:
                                events += [state]
                                connection.connect()
                            case .Connecting:
                                events += [state]
                            case .Connected:
                                events += [state]
                                client.close()
                            case .Disconnected:
                                events += [state]
                                // Forced
                                client.transition(.Failed, withErrorInfo: ARTErrorInfo())
                            case .Suspended:
                                events += [state]
                                // Forced
                                client.transition(.Disconnected)
                            case .Closing:
                                events += [state]
                            case .Closed:
                                events += [state]
                                // Forced
                                client.transition(.Suspended)
                            case .Failed:
                                events += [state]
                                expect(errorInfo).toNot(beNil(), description: "Error is nil")
                                done()
                            }
                        }
                    }

                    expect(events).to(haveCount(8), description: "Missing some states")
                }

                // RTN4b
                it("should emit states on a new connection") {
                    let connection = ARTRealtime(options: AblyTests.commonAppSetup()).connection()
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: 25.0) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Connecting:
                                events += [state]
                            case .Connected:
                                events += [state]
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(events).to(haveCount(2), description: "Missing CONNECTING or CONNECTED state")
                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.Connecting.rawValue), description: "Should be CONNECTING state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.Connected.rawValue), description: "Should be CONNECTED state")
                }

                // RTN4c
                it("should emit states when connection is closed") {
                    let connection = ARTRealtime(options: AblyTests.commonAppSetup()).connection()
                    var events: [ARTRealtimeConnectionState] = []

                    waitUntil(timeout: 25.0) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Connected:
                                connection.close()
                            case .Closing:
                                events += [state]
                            case .Closed:
                                events += [state]
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(events).to(haveCount(2), description: "Missing CLOSING or CLOSED state")
                    expect(events[0].rawValue).to(equal(ARTRealtimeConnectionState.Closing.rawValue), description: "Should be CLOSING state")
                    expect(events[1].rawValue).to(equal(ARTRealtimeConnectionState.Closed.rawValue), description: "Should be CLOSED state")
                }

                // RTN4d
                it("should have the current state") {
                    let options = AblyTests.commonAppSetup()
                    options.autoConnect = false
                    let connection = ARTRealtime(options: options).connection()
                    expect(connection.state.rawValue).to(equal(0), description: "Missing INITIALIZED state")
                }

                // RTN4e
                it("should have the current state on the event change") {
                    let connection = ARTRealtime(options: AblyTests.commonAppSetup()).connection()
                    var lastState = ARTRealtimeConnectionState.Initialized

                    waitUntil(timeout: 25.0) { done in
                        connection.eventEmitter.on { state, errorInfo in
                            switch state {
                            case .Connected:
                                lastState = state
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(lastState.rawValue).to(equal(2), description: "Missing state argument")
                }

                // RTN4f
                it("should have the reason which contains an ErrorInfo") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRealtime(options: options)
                    let connection = client.connection()

                    var errorInfo: ARTErrorInfo?
                    waitUntil(timeout: 30.0) { done in
                        connection.eventEmitter.on { state, reason in
                            switch state {
                            case .Connected:
                                // Forced
                                client.transition(.Failed, withErrorInfo: ARTErrorInfo())
                            case .Failed:
                                errorInfo = reason
                                done()
                            default:
                                break
                            }
                        }
                    }

                    expect(errorInfo).toNot(beNil())
                }
            }
        }
    }
}
