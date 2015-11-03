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

            context("query params") {
                // RTN2
                fit("should connect to the default host") {
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
            }
        }
    }
}
