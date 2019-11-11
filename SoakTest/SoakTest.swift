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

let randomSeed: Int = 13
let concurrentConnections: Int = 1000
let runTime: TimeInterval = 60 * 30

class SoakTest: XCTestCase {
    func testSoak() {
        ARTWebSocketTransport.setWebSocketClass(SoakTestWebSocket.self)
        ARTHttp.setURLSessionClass(SoakTestURLSession.self)

        var queues: [DispatchQueue] = []
        
        for i in (0 ..< concurrentConnections) {
            let queue = DispatchQueue(label: "io.ably.soakTest.\(i)")
            let internalQueue = DispatchQueue(label: "io.ably.soakTest.internal.\(i)")
            queues.append(queue)
            queues.append(internalQueue)

            queue.async {
                let options = ARTClientOptions(key: "fake:key")
                options.autoConnect = false
                options.logLevel = .debug
                options.dispatchQueue = queue
                options.internalDispatchQueue = internalQueue
                let realtime = ARTRealtime(options: options)
                realtime.internal.setReachabilityClass(SoakTestReachability.self)
                
                queue.afterSeconds(between: 0.0 ... 2.0) {
                    realtime.connection.on { state in
                        print("got connection notification; error: \(String(describing: state?.reason))")
                        queue.afterSeconds(between: 0.0 ... 120.0) {
                            realtime.close()
                        }
                    }
                    realtime.connect()
                }
                
                sendMessages(realtime: realtime, queue: queue)
            }
        }
        
        Thread.sleep(forTimeInterval: runTime)
        
        for queue in queues {
            queue.suspend()
        }
    }
}

func sendMessages(realtime: ARTRealtime, queue: DispatchQueue) {
    queue.afterSeconds(between: 0.1 ... 1.0) {
        if realtime.connection.state == .closed {
            return
        }
        sendMessages(realtime: realtime, queue: queue)

        let channel = realtime.channels.get("channel.\(Int((0 ... 100).randomWithin()))")
        channel.subscribe { message in
            print("got message: \(message)")
        }
        channel.publish("fakeMessage", data: messageFixtures.randomElement(using: &seededRandomNumberGenerator) ?? nil) { error in
                print("got message ack; error: \(String(describing: error))")
        }
    }
}

let messageFixtures: [Any?] = [
    "a string",
    ["some", ["values": 456]],
    nil,
]

var randDouble : () -> Double = {
    srand48(randomSeed)
    return { drand48() }
}()

class SeededRandomNumberGenerator : RandomNumberGenerator {
    func next() -> UInt64 {
        return UInt64((0 ... UInt64.max).randomWithin())
    }
}

var seededRandomNumberGenerator = SeededRandomNumberGenerator()

extension ClosedRange where Bound : BinaryFloatingPoint {
    func randomWithin() -> Double {
        return Double(lowerBound) + Double(upperBound - lowerBound) * randDouble()
    }
}

extension ClosedRange where Bound : BinaryInteger {
    func randomWithin() -> Double {
        return (Double(self.lowerBound) ... Double(self.upperBound)).randomWithin()
    }
}

extension Double {
    func secondsFromNow() -> DispatchTime {
        return DispatchTime.now() + .milliseconds(Int(self * 1000))
    }
}

extension DispatchQueue {
    func afterSeconds(between secondsRange: ClosedRange<Double>, execute: @escaping () -> Void) {
        self.asyncAfter(deadline: secondsRange.randomWithin().secondsFromNow(), execute: execute)
    }
}

extension Bool {
    func times(_ times: Int, outOf: Int) -> Bool {
        if (0 ... outOf).randomWithin() < Double(times) {
            return self
        } else {
            return !self
        }
    }
}

