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
                    let options = AblyTests.commonAppSetup() //Same as Rest
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

                fit("should connect with query string params") {
                    let options = AblyTests.commonAppSetup() //Same as Rest
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
                                    // TODO: Check if it is possible to create a custom matcher with Nimble and check each field
                                    let queryParams = query.componentsSeparatedByString("&")
                                    expect(queryParams).to(haveCount(4))
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

                fit("should connect with query string params including clientId") {
                    let options = AblyTests.commonAppSetup() //Same as Rest
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
                                    // TODO: Check if it is possible to create a custom matcher with Nimble and check each field
                                    let queryParams = query.componentsSeparatedByString("&")
                                    expect(queryParams).to(haveCount(5))
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
