//
//  SoakTestWebSocket.swift
//  Ably-iOS-SoakTest
//
//  Copyright © 2019 Ably. All rights reserved.
//

import Foundation
import Ably.Private
import SocketRocketAblyFork

class SoakTestWebSocket: NSObject, ARTWebSocket {
    var delegate: ARTWebSocketDelegate?
    
    var readyState: SRReadyState
    
    required init(urlRequest request: URLRequest) {
        readyState = .CLOSED
    }
    
    func setDelegateDispatchQueue(_ queue: DispatchQueue) {
    }
    
    func open() {
    }
    
    func close(withCode code: Int, reason: String?) {
    }
    
    func send(_ message: Any?) {
    }
}
