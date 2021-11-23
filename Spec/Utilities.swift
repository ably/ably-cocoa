import Ably
import Nimble
import Quick
import Foundation
                private var jsonEncoder: ARTJsonLikeEncoder!

                private var eventEmitter = ARTInternalEventEmitter<NSString, AnyObject>(queue: AblyTests.queue)
                private var receivedFoo1: Int?
                private var receivedFoo2: Int?
                private var receivedBar: Int?
                private var receivedBarOnce: Int?
                private var receivedAll: Int?
                private var receivedAllOnce: Int?
                private weak var listenerFoo1: ARTEventListener?
                private weak var listenerAll: ARTEventListener?
                private let data = ["test": "test"]
                private let extras = ["push": ["key": "value"]]
                private let clientId = "clientId"

class Utilities: XCTestCase {

override class var defaultTestSuite : XCTestSuite {
    let _ = jsonEncoder
    let _ = eventEmitter
    let _ = receivedFoo1
    let _ = receivedFoo2
    let _ = receivedBar
    let _ = receivedBarOnce
    let _ = receivedAll
    let _ = receivedAllOnce
    let _ = listenerFoo1
    let _ = listenerAll
    let _ = data
    let _ = extras
    let _ = clientId

    return super.defaultTestSuite
}

        

            
                func beforeEach__Utilities__JSON_Encoder() {
print("START HOOK: Utilities.beforeEach__Utilities__JSON_Encoder")

                    jsonEncoder = ARTJsonLikeEncoder()
                    jsonEncoder.delegate = ARTJsonEncoder()
print("END HOOK: Utilities.beforeEach__Utilities__JSON_Encoder")

                }

                func test__001__Utilities__JSON_Encoder__should_decode_a_protocol_message_that_has_an_error_without_a_message() {
beforeEach__Utilities__JSON_Encoder()

                    let jsonObject: NSDictionary = [
                        "action": 9,
                        "error": [
                            "code": 40142,
                            "statusCode": "401",
                        ]
                    ]
                    let data = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
                    guard let protocolMessage = try? jsonEncoder.decodeProtocolMessage(data) else {
                        fail("Decoder has failed"); return
                    }
                    guard let error = protocolMessage.error else {
                        fail("Error is empty"); return
                    }
                    expect(error.message).to(equal(""))
                }

                func test__002__Utilities__JSON_Encoder__should_encode_a_protocol_message_that_has_invalid_data() {
beforeEach__Utilities__JSON_Encoder()

                    let pm = ARTProtocolMessage()
                    pm.action = .message
                    pm.channel = "foo"
                    pm.messages = [ARTMessage(name: "status", data: NSDate(), clientId: "user")]
                    var result: Data?
                    expect{ result = try jsonEncoder.encode(pm) }.to(throwError { error in
                        let e = error as NSError
                        expect(e.domain).to(equal(ARTAblyErrorDomain))
                        expect(e.code).to(equal(Int(ARTClientCodeError.invalidType.rawValue)))
                        expect(e.localizedDescription).to(contain("Invalid type in JSON write"))
                        })
                    expect(result).to(beNil())
                }

                func test__003__Utilities__JSON_Encoder__should_decode_data_with_malformed_JSON() {
beforeEach__Utilities__JSON_Encoder()

                    let malformedJSON = "{...}"
                    let data = malformedJSON.data(using: String.Encoding.utf8)!
                    var result: AnyObject?
                    expect{ result = try ARTJsonEncoder().decode(data) as AnyObject? }.to(throwError { error in
                        let e = error as NSError
                        expect(e.localizedDescription).to(contain("data couldn’t be read"))
                    })
                    expect(result).to(beNil())
                }

                func test__004__Utilities__JSON_Encoder__should_decode_data_with_malformed_MsgPack() {
beforeEach__Utilities__JSON_Encoder()

                    let data = NSData()
                    var result: AnyObject?
                    expect{ result = try ARTMsgPackEncoder().decode(data as Data) as! (Data) as (Data) as AnyObject? }.to(throwError { error in
                        expect(error).toNot(beNil())
                    })
                    expect(result).to(beNil())
                }

                
                    func test__005__Utilities__JSON_Encoder__in_Realtime__should_handle_and_emit_the_invalid_data_error() {
beforeEach__Utilities__JSON_Encoder()

                        let options = AblyTests.commonAppSetup()
                        let realtime = ARTRealtime(options: options)
                        defer { realtime.close() }
                        let channel = realtime.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish("test", data: NSDate()) { error in
                                guard let error = error else {
                                    fail("Error shouldn't be nil"); done(); return
                                }
                                expect(error.message).to(contain("encoding failed"))
                                expect(error.reason).to(contain("must be NSString, NSData, NSArray or NSDictionary"))
                                done()
                            }
                        }
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([ARTMessage(name: nil, data: NSDate()), ARTMessage(name: nil, data: NSDate())]) { error in
                                guard let error = error else {
                                    fail("Error shouldn't be nil"); done(); return
                                }
                                expect(error.message).to(contain("encoding failed"))
                                expect(error.reason).to(contain("must be NSString, NSData, NSArray or NSDictionary"))
                                done()
                            }
                        }
                    }

                    func test__006__Utilities__JSON_Encoder__in_Realtime__should_ignore_invalid_transport_message() {
beforeEach__Utilities__JSON_Encoder()

                        let options = AblyTests.commonAppSetup()
                        let realtime = ARTRealtime(options: options)
                        defer { realtime.close() }
                        let channel = realtime.channels.get("foo")

                        // Garbage values (whatever is on the heap)
                        let bytes = UnsafeMutablePointer<Int>.allocate(capacity: 1)
                        defer { bytes.deallocate() }
                        let data = NSData(bytes: bytes, length: MemoryLayout<Int>.size)

                        waitUntil(timeout: testTimeout) { done in
                            channel.attach { error in
                                expect(error).to(beNil())
                                realtime.connection.once { _ in
                                    fail("Should not receive any connection change state")
                                }
                                channel.once { _ in
                                    fail("Should not receive any channel change state")
                                }
                                channel.subscribe { _ in
                                    fail("Should not receive any message")
                                }
                                var result: AnyObject?
                                expect{ result = realtime.internal.transport?.receive(with: data as Data) }.toNot(raiseException())
                                expect(result).to(beNil())
                                done()
                            }
                        }

                        realtime.connection.off()
                        channel.off()
                        channel.unsubscribe()
                    }

                
                    func test__007__Utilities__JSON_Encoder__in_Rest__should_handle_and_emit_the_invalid_data_error() {
beforeEach__Utilities__JSON_Encoder()

                        let options = AblyTests.commonAppSetup()
                        let rest = ARTRest(options: options)
                        let channel = rest.channels.get("foo")
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish("test", data: NSDate()) { error in
                                guard let error = error else {
                                    fail("Error shouldn't be nil"); done(); return
                                }
                                expect(error.message).to(contain("encoding failed"))
                                expect(error.reason).to(contain("must be NSString, NSData, NSArray or NSDictionary"))
                                done()
                            }
                        }
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish([ARTMessage(name: nil, data: NSDate()), ARTMessage(name: nil, data: NSDate())]) { error in
                                guard let error = error else {
                                    fail("Error shouldn't be nil"); done(); return
                                }
                                expect(error.message).to(contain("encoding failed"))
                                expect(error.reason).to(contain("must be NSString, NSData, NSArray or NSDictionary"))
                                done()
                            }
                        }
                    }

                    func test__008__Utilities__JSON_Encoder__in_Rest__should_ignore_invalid_response_payload() {
beforeEach__Utilities__JSON_Encoder()

                        let options = AblyTests.commonAppSetup()
                        let rest = ARTRest(options: options)
                        let testHTTPExecutor = TestProxyHTTPExecutor(options.logHandler)
                        rest.internal.httpExecutor = testHTTPExecutor
                        let channel = rest.channels.get("foo")

                        // Garbage values (whatever is on the heap)
                        let bytes = UnsafeMutablePointer<Int>.allocate(capacity: 1)
                        defer { bytes.deallocate() }
                        let data = NSData(bytes: bytes, length: MemoryLayout<Int>.size)

                        testHTTPExecutor.simulateIncomingPayloadOnNextRequest(data as Data)
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: nil) { error in
                                expect(error).to(beNil()) //ignored
                                done()
                            }
                        }

                        testHTTPExecutor.simulateIncomingPayloadOnNextRequest(data as Data)
                        waitUntil(timeout: testTimeout) { done in
                            channel.history { result, error in
                                guard let error = error else {
                                    fail("Error is nil"); done(); return
                                }
                                expect(error.reason).to(contain("JSON text did not start with array or object and option to allow fragments not set"))
                                done()
                            }
                        }
                    }

            

                func beforeEach__Utilities__EventEmitter() {
print("START HOOK: Utilities.beforeEach__Utilities__EventEmitter")

                    eventEmitter = ARTInternalEventEmitter(queue: AblyTests.queue)
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
print("END HOOK: Utilities.beforeEach__Utilities__EventEmitter")

                }

                func test__009__Utilities__EventEmitter__should_emit_events_to_all_relevant_listeners() {
beforeEach__Utilities__EventEmitter()

                    eventEmitter.emit("foo", with: 123 as AnyObject?)

                    expect(receivedFoo1).to(equal(123))
                    expect(receivedFoo2).to(equal(123))
                    expect(receivedBar).to(beNil())
                    expect(receivedAll).to(equal(123))
                    
                    eventEmitter.emit("bar", with:456 as AnyObject?)
                    
                    expect(receivedFoo1).to(equal(123))
                    expect(receivedFoo2).to(equal(123))
                    expect(receivedBar).to(equal(456))
                    expect(receivedAll).to(equal(456))
                    
                    eventEmitter.emit("qux", with:789 as AnyObject?)
                    
                    expect(receivedAll).toEventually(equal(789), timeout: testTimeout)
                }
                
                func test__010__Utilities__EventEmitter__should_only_call_once_listeners_once_for_its_event() {
beforeEach__Utilities__EventEmitter()

                    eventEmitter.emit("foo", with: 123 as AnyObject?)

                    expect(receivedBarOnce).to(beNil())
                    expect(receivedAllOnce).to(equal(123))
                    
                    eventEmitter.emit("bar", with: 456 as AnyObject?)
                    
                    expect(receivedBarOnce).to(equal(456))
                    expect(receivedAllOnce).to(equal(123))

                    eventEmitter.emit("bar", with: 789 as AnyObject?)
                    
                    expect(receivedBarOnce).to(equal(456))
                    expect(receivedAllOnce).to(equal(123))
                }
                
                
                    func test__011__Utilities__EventEmitter__calling_off_with_a_single_listener_argument__should_stop_receiving_events_when_calling_off_with_a_single_listener_argument() {
beforeEach__Utilities__EventEmitter()

                        eventEmitter.off(listenerFoo1!)
                        eventEmitter.emit("foo", with: 123 as AnyObject?)
                        
                        expect(receivedFoo1).to(beNil())
                        expect(receivedFoo2).to(equal(123))
                        expect(receivedAll).to(equal(123))
                        
                        eventEmitter.emit("bar", with: 222 as AnyObject?)
                        
                        expect(receivedFoo2).to(equal(123))
                        expect(receivedAll).to(equal(222))
                        
                        eventEmitter.off(listenerAll!)
                        eventEmitter.emit("bar", with: 333 as AnyObject?)
                        
                        expect(receivedAll).to(equal(222))
                    }

                    func skipped__test__012__Utilities__EventEmitter__calling_off_with_a_single_listener_argument__should_remove_the_timeout() {
beforeEach__Utilities__EventEmitter()

                        listenerFoo1!.setTimer(0.1, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        }).startTimer()
                        eventEmitter.off(listenerFoo1!)
                        waitUntil(timeout: DispatchTimeInterval.milliseconds(300)) { done in
                            AblyTests.queue.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                                done()
                            }
                        }
                    }
                
                
                    func test__013__Utilities__EventEmitter__calling_off_with_listener_and_event_arguments__should_still_receive_events_if_off_doesn_t_match_the_listener_s_criteria() {
beforeEach__Utilities__EventEmitter()

                        eventEmitter.off("foo", listener: listenerAll!)
                        eventEmitter.emit("foo", with: 111 as AnyObject?)

                        expect(receivedFoo1).to(equal(111))
                        expect(receivedAll).to(equal(111))
                    }

                    func test__014__Utilities__EventEmitter__calling_off_with_listener_and_event_arguments__should_stop_receive_events_if_off_matches_the_listener_s_criteria() {
beforeEach__Utilities__EventEmitter()

                        eventEmitter.off("foo", listener: listenerFoo1!)
                        eventEmitter.emit("foo", with: 111 as AnyObject?)

                        expect(receivedFoo1).to(beNil())
                        expect(receivedAll).to(equal(111))
                    }
                
                
                    func test__015__Utilities__EventEmitter__calling_off_with_no_arguments__should_remove_all_listeners() {
beforeEach__Utilities__EventEmitter()

                        eventEmitter.off()
                        eventEmitter.emit("foo", with: 111 as AnyObject?)
                        
                        expect(receivedFoo1).to(beNil())
                        expect(receivedFoo2).to(beNil())
                        expect(receivedAll).to(beNil())
                        
                        eventEmitter.emit("bar", with: 111 as AnyObject?)
                        
                        expect(receivedBar).to(beNil())
                        expect(receivedBarOnce).to(beNil())
                        expect(receivedAll).to(beNil())
                    }
                    
                    func test__016__Utilities__EventEmitter__calling_off_with_no_arguments__should_allow_listening_again() {
beforeEach__Utilities__EventEmitter()

                        eventEmitter.off()
                        eventEmitter.on("foo", callback: { receivedFoo1 = $0 as? Int })
                        eventEmitter.emit("foo", with: 111 as AnyObject?)
                        expect(receivedFoo1).to(equal(111))
                    }

                    func test__017__Utilities__EventEmitter__calling_off_with_no_arguments__should_remove_all_timeouts() {
beforeEach__Utilities__EventEmitter()

                        listenerFoo1!.setTimer(0.1, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        }).startTimer()
                        listenerAll!.setTimer(0.1, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        }).startTimer()
                        eventEmitter.off()
                        waitUntil(timeout: DispatchTimeInterval.milliseconds(300)) { done in
                            AblyTests.queue.asyncAfter(deadline: .now() + 0.15) {
                                done()
                            }
                        }
                    }

                
                    func test__018__Utilities__EventEmitter__the_timed_method__should_not_call_onTimeout_if_the_deadline_isn_t_reached() {
beforeEach__Utilities__EventEmitter()

                        weak var timer = listenerFoo1!.setTimer(0.2, onTimeout: {
                            fail("onTimeout callback shouldn't have been called")
                        })
                        waitUntil(timeout: DispatchTimeInterval.seconds(1)) { done in
                            timer?.startTimer()
                            eventEmitter.emit("foo", with: 123 as AnyObject?)
                            AblyTests.queue.asyncAfter(deadline: .now() + 0.3) {
                                expect(receivedFoo1).toNot(beNil())
                                done()
                            }
                        }
                    }

                    func test__019__Utilities__EventEmitter__the_timed_method__should_call_onTimeout_and_off_the_listener_if_the_deadline_is_reached() {
beforeEach__Utilities__EventEmitter()

                        var calledOnTimeout = false
                        let beforeEmitting = NSDate()
                        listenerFoo1!.setTimer(0.3, onTimeout: {
                            calledOnTimeout = true
                            expect(NSDate()).to(beCloseTo(beforeEmitting.addingTimeInterval(0.3), within: 0.2))
                        }).startTimer()
                        waitUntil(timeout: DispatchTimeInterval.milliseconds(500)) { done in
                            AblyTests.queue.asyncAfter(deadline: .now() + 0.35) {
                                expect(calledOnTimeout).to(beTrue())
                                eventEmitter.emit("foo", with: 123 as AnyObject?)
                                expect(receivedFoo1).to(beNil())
                                done()
                            }
                        }
                    }
                
                
                    
                    // RTE6a
                    func test__020__Utilities__EventEmitter__set_of_listeners__should_not_change_over_the_course_of_the_emit() {
beforeEach__Utilities__EventEmitter()

                        var firstCallbackCalled = false;
                        var secondCallbackCalled = false;
                        eventEmitter.on("a", callback: { _ in
                            firstCallbackCalled = true
                            eventEmitter.on("b", callback: { _ in
                                secondCallbackCalled = true
                            })
                        })
                        eventEmitter.emit("a", with: "123" as AnyObject?)
                        expect(firstCallbackCalled).to(beTrue())
                        expect(secondCallbackCalled).to(beFalse())
                    }

            

                func test__021__Utilities__Logger__should_have_a_history_of_logs() {
                    let options = AblyTests.commonAppSetup()
                    let realtime = ARTRealtime(options: options)
                    realtime.internal.logger.logLevel = .verbose
                    defer { realtime.close() }
                    let channel = realtime.channels.get("foo")

                    waitUntil(timeout: testTimeout) { done in
                        channel.attach { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }

                    expect(realtime.internal.logger.history.count).toNot(beGreaterThan(100))
                    expect(realtime.internal.logger.history.map{ $0.message }.first).to(contain("channel state transitions from 1 - Attaching to 2 - Attached"))
                    expect(realtime.internal.logger.history.filter{ $0.message.contains("realtime state transitions to 2 - Connected") }).to(haveCount(1))
                }
            
            

                func test__022__Utilities__maxMessageSize__calculates_maxMessageSize_of_a_Message_with_name_and_data() {
                    let message = ARTMessage(name: "this is name", data: data)
                    let expectedSize = "{\"test\":\"test\"}".count + message.name!.count
                    expect(message.messageSize()).to(equal(expectedSize))
                }

                func test__023__Utilities__maxMessageSize__calculates_maxMessageSize_of_a_Message_with_name__data_and_extras() {
                    let message = ARTMessage(name: "this is name", data: data)
                    message.extras = extras as ARTJsonCompatible
                    let expectedSize = "{\"test\":\"test\"}".count + "{\"push\":{\"key\":\"value\"}}".count + message.name!.count
                    expect(message.messageSize()).to(equal(expectedSize))
                }

                func test__024__Utilities__maxMessageSize__calculates_maxMessageSize_of_a_Message_with_name__data__clientId_and_extras() {
                    let message = ARTMessage(name: "this is name", data: data)
                    message.clientId = clientId
                    message.extras = extras as ARTJsonCompatible
                    let expectedSize = "{\"test\":\"test\"}".count + "{\"push\":{\"key\":\"value\"}}".count + clientId.count + message.name!.count
                    expect(message.messageSize()).to(equal(expectedSize))
                }
}
