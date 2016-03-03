//
//  Utilities.swift
//  ably
//
//  Created by Toni Cárdenas on 30/1/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Nimble
import Quick
import Foundation

class Utilities: QuickSpec {
    override func spec() {
        describe("Utilities") {
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
                    listenerFoo1 = eventEmitter.on("foo", call: { receivedFoo1 = $0 as? Int })
                    eventEmitter.on("foo", call: { receivedFoo2 = $0 as? Int })
                    eventEmitter.on("bar", call: { receivedBar = $0 as? Int })
                    eventEmitter.once("bar", call: { receivedBarOnce = $0 as? Int })
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
                        eventEmitter.on("foo", call: { receivedFoo1 = $0 as? Int })
                        eventEmitter.emit("foo", with: 111)
                        expect(receivedFoo1).to(equal(111))
                    }
                }
            }
        }
    }
}

