import Ably
import Quick
import Nimble
            private let options: ARTClientOptions = {
                let options = ARTClientOptions(key: "fake:key")
                options.autoConnect = false
                return options
            }()

class ObjectLifetimes: XCTestCase {

override class var defaultTestSuite : XCTestSuite {
    let _ = options

    return super.defaultTestSuite
}

        
            
            
                func test__001__ObjectLifetimes__user_code_releases_public_object__the_object_s_internal_child_s_back_reference_is_released_too() {
                    var realtime: ARTRealtime? = ARTRealtime(options: options)
                    weak var internalRealtime: ARTRealtimeInternal? = realtime!.internal
                    weak var internalConn: ARTConnectionInternal? = realtime!.connection.internal
                    weak var internalRest: ARTRestInternal? = realtime!.internal.rest

                    waitUntil(timeout: testTimeout) { done in
                        options.internalDispatchQueue.async {
                            realtime = nil // Schedule deallocation for later in this queue
                            expect(internalConn).toNot(beNil()) // Deallocation still hasn't happened.
                            expect(internalRealtime).toNot(beNil())
                            expect(internalRest).toNot(beNil())
                            done()
                        }
                    }

                    // Deallocation should happen here.

                    waitUntil(timeout: testTimeout) { done in
                        options.internalDispatchQueue.async {
                            expect(internalConn).to(beNil())
                            expect(internalRealtime).to(beNil())
                            expect(internalRest).to(beNil())
                            done()
                        }
                    }
                }

            
                func test__002__ObjectLifetimes__user_code_holds_only_reference_to_public_object_s_public_child__still_can_access_parent_s_internal_object() {
                    let conn = ARTRealtime(options: options).connection

                    waitUntil(timeout: testTimeout) { done in
                        conn.ping { _ in
                            done()
                        }
                    }
                }
                
                
                    func test__003__ObjectLifetimes__user_code_holds_only_reference_to_public_object_s_public_child__when_it_s_released__schedules_async_release_of_parent_s_internal_object_in_internal_queue() {
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
            
            
                func test__004__ObjectLifetimes__when_user_leaves_Realtime_open__still_works() {
                    let options = AblyTests.commonAppSetup()
                    
                    var client: ARTRealtime? = ARTRealtime(options: options)
                    
                    weak var weakClient = client!.internal
                    expect(weakClient).toNot(beNil())
                    defer { client?.close() }
                    
                    waitUntil(timeout: testTimeout) { done in
                        client!.channels.get("foo").subscribe(attachCallback: { _ in
                            client = nil
                            ARTRest(options: options).channels.get("foo").publish(nil, data: "bar")
                        }, callback: { msg in
                            expect(msg.data as? String).to(equal("bar"))
                            done()
                        })
                    }
                }

            
                func test__005__ObjectLifetimes__when_Realtime_is_closed_and_user_loses_its_reference__channels_don_t_leak() {
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
