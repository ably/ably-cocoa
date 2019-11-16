//
//  SoakTestURLSession.swift
//  Ably-iOS-SoakTest
//
//  Created by Toni Cárdenas on 09/11/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

import Foundation
import Ably.Private

class SoakTestURLSession : NSObject, ARTURLSession {
    required init(_ queue: DispatchQueue) {
    }
    
    func get(_ request: URLRequest, completion callback: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) -> URLSessionTask {
        return get(request, completion: callback) // TODO
    }
    
    func finishTasksAndInvalidate() {
    }
}
