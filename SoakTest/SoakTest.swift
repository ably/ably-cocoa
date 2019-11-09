//
//  SoakTest.swift
//  Ably-iOS-SoakTest
//
//  Created by Toni Cárdenas on 09/11/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

import Foundation
import XCTest
import Ably.Private

class SoakTest: XCTestCase {
    func testSoak() {
        ARTWebSocketTransport.setWebSocketClass(SoakTestWebSocket.self)
        ARTHttp.setURLSessionClass(SoakTestURLSession.self)
        if let realtime = (nil as ARTRealtime?) {
            realtime.internal.setReachabilityClass(SoakTestReachability.self)
        }
        
        XCTAssertTrue(true)
    }
}
