//
//  Utilities.swift
//  ably
//
//  Created by Toni Cárdenas on 30/1/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Ably
import Nimble
import Quick
import Foundation

class Utilities: QuickSpec {
    override func spec() {
        describe("Utilities") {

            context("JSON Encoder") {
                var jsonEncoder: ARTJsonLikeEncoder!
                beforeEach {
                    jsonEncoder = ARTJsonLikeEncoder()
                    jsonEncoder.delegate = ARTJsonEncoder()
                }

                it("should decode a protocol message that has an error without a message") {
                    let jsonObject: NSDictionary = [
                        "action": 9,
                        "error": [
                            "code": 40142,
                            "statusCode": "401",
                        ]
                    ]
                    let data = try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                    guard let protocolMessage = jsonEncoder.decodeProtocolMessage(data) else {
                        fail("Decoder has failed"); return
                    }
                    guard let error = protocolMessage.error else {
                        fail("Error is empty"); return
                    }
                    expect(error.message).to(equal(""))
                }
            }

            context("EventEmitter") {
                var eventEmitter = ARTEventEmitter()
                var receivedFoo1: Int?
                var receivedFoo2: Int?
                var receivedBar: Int?
                var receivedBarOnce: Int?
                var receivedAll: Int?
                var receivedAllOnce: Int?
                var listenerFoo1: ARTEventListener?
                var listenerAll: ARTEventListener?
                
                beforeEach {
                    eventEmitter = ARTEventEmitter()
                    receivedFoo1 = nil
                    receivedFoo2 = nil
                    receivedBar = nil
                    receivedBarOnce = nil
                    receivedAll = nil
                    listenerFoo1 = eventEmitter.on("foo", callback: { receivedFoo1 = $0 as? Int })
                    eventEmitter.on("foo", callback: { receivedFoo2 = $0 as? Int })
                    eventEmitter.on("bar", callback: { receivedBar = $0 as? Int })
                    eventEmitter.once("bar", callback: { receivedBarOnce = $0 as? Int })
                    listenerAll = eventEmitter.on { receivedAll = $0 as? Int }
                    eventEmitter.once { receivedAllOnce = $0 as? Int }
                }

                it("should emit events to all relevant listeners") {
                    eventEmitter.emit("foo", with: 123)

                    expect(receivedFoo1).to(equal(123))
                    expect(receivedFoo2).to(equal(123))
                    expect(receivedBar).to(beNil())
                    expect(receivedAll).to(equal(123))
                    
                    eventEmitter.emit("bar", with:456)
                    
                    expect(receivedFoo1).to(equal(123))
                    expect(receivedFoo2).to(equal(123))
                    expect(receivedBar).to(equal(456))
                    expect(receivedAll).to(equal(456))
                    
                    eventEmitter.emit("qux", with:789)
                    
                    expect(receivedAll).to(equal(789))
                }
                
                it("should only call once listeners once for its event") {
                    eventEmitter.emit("foo", with: 123)

                    expect(receivedBarOnce).to(beNil())
                    expect(receivedAllOnce).to(equal(123))
                    
                    eventEmitter.emit("bar", with: 456)
                    
                    expect(receivedBarOnce).to(equal(456))
                    expect(receivedAllOnce).to(equal(123))

                    eventEmitter.emit("bar", with: 789)
                    
                    expect(receivedBarOnce).to(equal(456))
                    expect(receivedAllOnce).to(equal(123))
                }
                
                context("calling off with a single listener argument") {
                    it("should stop receiving events when calling off with a single listener argument") {
                        eventEmitter.off(listenerFoo1!)
                        eventEmitter.emit("foo", with: 123)
                        
                        expect(receivedFoo1).to(beNil())
                        expect(receivedFoo2).to(equal(123))
                        expect(receivedAll).to(equal(123))
                        
                        eventEmitter.emit("bar", with: 222)
                        
                        expect(receivedFoo2).to(equal(123))
                        expect(receivedAll).to(equal(222))
                        
                        eventEmitter.off(listenerAll!)
                        eventEmitter.emit("bar", with: 333)
                        
                        expect(receivedAll).to(equal(222))
                    }

                    it("should remove the timeout") {
                        eventEmitter.timed(listenerFoo1!, deadline: 0.1, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        })
                        eventEmitter.off(listenerFoo1!)
                        waitUntil(timeout: 0.3) { done in
                            delay(0.15) {
                                done()
                            }
                        }
                    }
                }
                
                context("calling off with listener and event arguments") {
                    it("should still receive events if off doesn't match the listener's criteria") {
                        eventEmitter.off("foo", listener: listenerAll!)
                        eventEmitter.emit("foo", with: 111)

                        expect(receivedFoo1).to(equal(111))
                        expect(receivedAll).to(equal(111))
                    }
                
                    it("should stop receive events if off matches the listener's criteria") {
                        eventEmitter.off("foo", listener: listenerFoo1!)
                        eventEmitter.emit("foo", with: 111)

                        expect(receivedFoo1).to(beNil())
                        expect(receivedAll).to(equal(111))
                    }
                }
                
                context("calling off with no arguments") {
                    it("should remove all listeners") {
                        eventEmitter.off()
                        eventEmitter.emit("foo", with: 111)
                        
                        expect(receivedFoo1).to(beNil())
                        expect(receivedFoo2).to(beNil())
                        expect(receivedAll).to(beNil())
                        
                        eventEmitter.emit("bar", with: 111)
                        
                        expect(receivedBar).to(beNil())
                        expect(receivedBarOnce).to(beNil())
                        expect(receivedAll).to(beNil())
                    }
                    
                    it("should allow listening again") {
                        eventEmitter.off()
                        eventEmitter.on("foo", callback: { receivedFoo1 = $0 as? Int })
                        eventEmitter.emit("foo", with: 111)
                        expect(receivedFoo1).to(equal(111))
                    }

                    it("should remove all timeouts") {
                        eventEmitter.timed(listenerFoo1!, deadline: 0.1, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        })
                        eventEmitter.timed(listenerAll!, deadline: 0.1, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        })
                        eventEmitter.off()
                        waitUntil(timeout: 0.3) { done in
                            delay(0.15) {
                                done()
                            }
                        }
                    }
                }

                context("the timed method") {
                    it("should not call onTimeout if the deadline isn't reached") {
                        eventEmitter.timed(listenerFoo1!, deadline: 0.2, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        })
                        waitUntil(timeout: 0.4) { done in
                            delay(0.1) {
                                eventEmitter.emit("foo", with: 123)
                                delay(0.15) {
                                    expect(receivedFoo1).toNot(beNil())
                                    done()
                                }
                            }
                        }
                    }

                    it("should call onTimeout and off the listener if the deadline is reached") {
                        var calledOnTimeout = false
                        let beforeEmitting = NSDate()
                        eventEmitter.timed(listenerFoo1!, deadline: 0.3, onTimeout: {
                            calledOnTimeout = true
                            expect(NSDate()).to(beCloseTo(beforeEmitting.dateByAddingTimeInterval(0.3), within: 0.2))
                        })
                        waitUntil(timeout: 0.5) { done in
                            delay(0.35) {
                                expect(calledOnTimeout).to(beTrue())
                                eventEmitter.emit("foo", with: 123)
                                expect(receivedFoo1).to(beNil())
                                done()
                            }
                        }
                    }
                }
            }
        }
    }
}

