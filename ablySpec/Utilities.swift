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
                var receivedFooOrBar: Int?
                var receivedBarOnce: Int?
                var receivedAll: Int?
                var receivedAllOnce: Int?
                var listenerFoo1: ARTEventListener?
                var listenerFoo2: ARTEventListener?
                var listenerBar: ARTEventListener?
                var listenerFooOrBar: ARTEventListener?
                var listenerBarOnce: ARTEventListener?
                var listenerAll: ARTEventListener?
                var listenerAllOnce: ARTEventListener?
                
                beforeEach {
                    eventEmitter = ARTEventEmitter()
                    receivedFoo1 = nil
                    receivedFoo2 = nil
                    receivedBar = nil
                    receivedFooOrBar = nil
                    receivedBarOnce = nil
                    receivedAll = nil
                    listenerFoo1 = eventEmitter.on("foo", call: { receivedFoo1 = $0 as? Int })
                    listenerFoo2 = eventEmitter.on("foo", call: { receivedFoo2 = $0 as? Int })
                    listenerBar = eventEmitter.on("bar", call: { receivedBar = $0 as? Int })
                    listenerFooOrBar = eventEmitter.on("foo", call: { receivedFooOrBar = $0 as? Int })
                    eventEmitter.on("bar", callListener: listenerFooOrBar!)
                    listenerBarOnce = eventEmitter.once("bar", call: { receivedBarOnce = $0 as? Int })
                    listenerAll = eventEmitter.onAll { receivedAll = $0 as? Int }
                    listenerAllOnce = eventEmitter.onceAll { receivedAllOnce = $0 as? Int }
                }

                it("should emit events to all relevant listeners") {
                    eventEmitter.emit("foo", with: 123)

                    expect(receivedFoo1).to(equal(123))
                    expect(receivedFoo2).to(equal(123))
                    expect(receivedBar).to(beNil())
                    expect(receivedFooOrBar).to(equal(123))
                    expect(receivedAll).to(equal(123))
                    
                    eventEmitter.emit("bar", with:456)
                    
                    expect(receivedFoo1).to(equal(123))
                    expect(receivedFoo2).to(equal(123))
                    expect(receivedBar).to(equal(456))
                    expect(receivedFooOrBar).to(equal(456))
                    expect(receivedAll).to(equal(456))
                    
                    eventEmitter.emit("qux", with:789)
                    
                    expect(receivedFooOrBar).to(equal(456))
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
                
                it("should stop receiving events when calling off") {
                    eventEmitter.offAll(listenerFoo1!)
                    eventEmitter.emit("foo", with: 123)
                    
                    expect(receivedFoo1).to(beNil())
                    expect(receivedFoo2).to(equal(123))
                    expect(receivedFooOrBar).to(equal(123))
                    expect(receivedAll).to(equal(123))
                    
                    eventEmitter.off("foo", listener: listenerFooOrBar!)
                    eventEmitter.emit("foo", with: 456)
                    
                    expect(receivedFoo2).to(equal(456))
                    expect(receivedFooOrBar).to(equal(123))
                    
                    eventEmitter.emit("bar", with: 789)
                    
                    expect(receivedFooOrBar).to(equal(789))
                    
                    eventEmitter.off("foo", listener: listenerAll!)
                    eventEmitter.emit("foo", with: 111)
                    
                    expect(receivedAll).to(equal(789))
                    
                    eventEmitter.emit("bar", with: 222)
                    
                    expect(receivedAll).to(equal(222))
                }

                it("should receive only once after calling onAll and then once") {
                    eventEmitter.once("foo", callListener: listenerAll!)

                    eventEmitter.emit("foo", with: 123)
                    expect(receivedAll).to(equal(123))
                    eventEmitter.emit("bar", with: 456)
                    expect(receivedAll).to(equal(456))

                    eventEmitter.emit("foo", with: 111)
                    expect(receivedAll).to(equal(456))
                    eventEmitter.emit("bar", with: 222)
                    expect(receivedAll).to(equal(222))
                }
            }
        }
    }
}

