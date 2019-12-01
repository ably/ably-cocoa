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
let runTime: TimeInterval = 60 * 25

class SoakTest: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

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
                let options: ARTClientOptions = {
                    if true.times(1, outOf: 2) {
                        return ARTClientOptions(key: "fake:key")
                    } else {
                        let options = ARTClientOptions()
                        options.authUrl = NSURL(string: "http://fakeauth.com") as URL?
                        return options
                    }
                }()
                options.autoConnect = false
                options.logLevel = .debug
                options.dispatchQueue = queue
                options.internalDispatchQueue = internalQueue
                let realtime = ARTRealtime(options: options)
                realtime.internal.setReachabilityClass(SoakTestReachability.self)

                realtime.connection.on { state in
                    print("got connection notification; error: \(String(describing: state?.reason))")
                }

                realtimeOperations(realtime: realtime, queue: queue)
                channelsOperations(realtime: realtime, queue: queue)
            }
        }
        
        Thread.sleep(forTimeInterval: runTime)
        
        for queue in queues {
            queue.suspend()
        }
    }
}

func realtimeOperations(realtime: ARTRealtime, queue: DispatchQueue) {
    queue.afterSeconds(between: 0.1 ... 1.0) {
        realtimeOperations(realtime: realtime, queue: queue)
    }

    queue.afterSeconds(between: 0.1 ... 10.0) {
        realtime.connect()
    }

    if true.times(1, outOf: 20) {
        queue.afterSeconds(between: 0.0 ... 120.0) {
            realtime.close()
        }
    }
    
    queue.afterSeconds(between: 0.1 ... 3.0) {
        realtime.ping { error in
            print("pinged; error: \(String(describing: error))")
        }
    }
}

func channelsOperations(realtime: ARTRealtime, queue: DispatchQueue) {
    queue.afterSeconds(between: 0.1 ... 1.0) {
        if realtime.connection.state == .closed {
            return
        }
        channelsOperations(realtime: realtime, queue: queue)

        let channel = realtime.channels.get("channel.\(Int((0 ... 100).randomWithin()))")
        
        queue.afterSeconds(between: 0.1 ... 1) {
            channel.attach { error in
                print("\(channel.name): attached; error: \(String(describing: error))")
            }
        }
        
        queue.afterSeconds(between: 0.1 ... 60) {
            channel.detach { error in
                print("\(channel.name): detached; error: \(String(describing: error))")
            }
        }
        
        queue.afterSeconds(between: 0.3 ... 2) {
            channel.subscribe { message in
                print("\(channel.name): got message: \(message)")
            }
        }
        
        queue.afterSeconds(between: 0.5 ... 3) {
            channel.publish("fakeMessage", data: randomMessageData()) { error in
                    print("\(channel.name): got message ack; error: \(String(describing: error))")
            }
        }
        
        queue.afterSeconds(between: 0.1 ... 1) {
            realtime.channels.exists(channel.name)
        }
        
        queue.afterSeconds(between: 0.1 ... 2) {
            realtime.channels.release(channel.name) { error in
                print("\(channel.name): released; error: \(String(describing: error))")
            }
        }
        
        if true.times(1, outOf: 10) {
            for channel in realtime.channels {
                _ = channel
            }
        }
    }
}

extension ARTRealtimeChannels: Sequence {
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self.iterate())
    }
}

let messageFixtures: [Any?] = [
    "a string",
    ["some", ["values": 456]],
    nil,
]

func randomMessageData() -> Any? {
    return messageFixtures.randomElement(using: &seededRandomNumberGenerator) as Any?
}

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

