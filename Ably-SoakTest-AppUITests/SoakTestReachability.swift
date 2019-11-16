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
    required init(logger: ARTLog, queue: DispatchQueue) {
    }
    
    func listen(forHost host: String, callback: @escaping (Bool) -> Void) {
    }
    
    func off() {
    }
}
