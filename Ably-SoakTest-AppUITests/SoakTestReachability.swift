//
//  SoakTestReachability.swift
//  Ably-iOS-SoakTest
//
//  Created by Toni Cárdenas on 09/11/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

import Foundation
import Ably.Private

class SoakTestReachability : NSObject, ARTReachability {
    let queue: DispatchQueue
    var callback: ((Bool) -> Void)?
    var isReachable = true

    required init(logger: ARTLog, queue: DispatchQueue) {
        self.queue = queue
        super.init()
        waitAndToggle()
    }
    
    func listen(forHost host: String, callback: @escaping (Bool) -> Void) {
        self.callback = callback
    }
    
    func off() {
        self.callback = nil
    }
    
    func waitAndToggle() {
        queue.afterSeconds(between: (0.1 ... 60.0 * 5)) {
            self.isReachable = !self.isReachable

            if let callback = self.callback {
                callback(self.isReachable)
            }
            
            self.waitAndToggle()
        }
    }
}
