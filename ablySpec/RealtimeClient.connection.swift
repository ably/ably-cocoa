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

class RestClientConnection: QuickSpec {

    override func spec() {
        describe("Connection") {
            // RTN1
            fit("should support additional transports") {
                // Only uses websocket transport.
            }
        }
    }

}