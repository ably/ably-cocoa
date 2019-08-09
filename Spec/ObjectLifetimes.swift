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
            let options = ARTClientOptions(key: "fake:key")
            options.autoConnect = false
            
            context("user code releases public object") {
                it("the object's internal child's back-reference is released too") {
                    var realtime: ARTRealtime? = ARTRealtime(options: options)
                    weak var internalRealtime: ARTRealtimeInternal? = realtime!.internal
                    weak var internalConn: ARTConnectionInternal? = realtime!.connection.internal

                    waitUntil(timeout: testTimeout) { done in
                        options.internalDispatchQueue.async {
                            realtime = nil // Schedule deallocation for later in this queue
                            expect(internalConn).toNot(beNil()) // Deallocation still hasn't happened.
                            expect(internalRealtime).toNot(beNil())
                            done()
                        }
                    }

                    // Deallocation should happen here.

                    waitUntil(timeout: testTimeout) { done in
                        options.internalDispatchQueue.async {
                            expect(internalConn).to(beNil())
                            expect(internalRealtime).to(beNil())
                            done()
                        }
                    }
                }
            }

            context("user code holds only reference to public object's public child") {
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

            context("when Realtime is closed and user loses its reference") {
                it("channels don't leak") {
                    let options = AblyTests.commonAppSetup()

                    var client: ARTRealtime? = ARTRealtime(options: options)
                    weak var weakClient = client!.internal

                    var channel: ARTRealtimeChannel? = client!.channels.get("foo")
                    weak var weakChannel = channel!.internal

                    waitUntil(timeout: testTimeout) { done in
                        channel!.attach { errorInfo in
                            expect(errorInfo).to(beNil())
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        client!.connection.on(.closed) { _ in
                            done()
                        }
                        client!.close()
                    }

                    waitUntil(timeout: testTimeout) { done in
                        AblyTests.queue.async {
                            client = nil // should enqueue a release
                            channel = nil // should enqueue a release
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        AblyTests.queue.async {
                            expect(weakClient).to(beNil())
                            expect(weakChannel).to(beNil())
                            done()
                        }
                    }
                }
            }
        }
    }
}
