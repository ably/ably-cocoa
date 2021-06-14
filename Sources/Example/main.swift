//
//  File.swift
//  
//
//  Created by Ben Butterworth on 14/06/2021.
//

import Foundation
import SocketRocket
import Ably

let API_KEY = "set your api key here"

let client = ARTRealtime(key: API_KEY)
print(client)
client.connection.on { stateChange in
    let stateChange = stateChange!
    switch stateChange.current {
    case .connected:
        print("connected!")
    case .failed:
        print("failed! \(String(describing: stateChange.reason))")
    default:
        break
    }
}
sleep(5000)

