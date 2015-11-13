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
        }
    }
}
