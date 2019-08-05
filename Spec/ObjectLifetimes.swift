//
//  ObjectLifetimes.swift
//  Ably
//
//  Created by Toni Cárdenas on 05/08/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

import Ably
import Quick
import Nimble

class ObjectLifetimes: QuickSpec {
    override func spec() {
        describe("ObjectLifetimes") {
            context("user code holds only reference to public object's public child") {
                let options = ARTClientOptions(key: "fake:key")
                options.autoConnect = false

                it("still can access parent's internal object") {
                    let conn = ARTRealtime(options: options).connection

                    waitUntil(timeout: testTimeout) { done in
                        conn.ping { _ in
                            done()
                        }
                    }
                }
                
                context("when it's released") {
                    it("schedules async release of parent's internal object in internal queue") {
                        var conn: ARTConnection? = ARTRealtime(options: options).connection
                        weak var weakConn = conn!.internal_nosync

                        waitUntil(timeout: testTimeout) { done in
                            options.internalDispatchQueue.async {
                                conn = nil // Schedule deallocation for later in this queue
                                expect(weakConn).toNot(beNil()) // Deallocation still hasn't happened.
                                done()
                            }
                        }
                        
                        // Deallocation should happen here.
                        
                        waitUntil(timeout: testTimeout) { done in
                            options.internalDispatchQueue.async {
                                expect(weakConn).to(beNil())
                                done()
                            }
                        }
                    }
                }
            }
        }
    }
}
