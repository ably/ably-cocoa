//
//  RestChannel.swift
//  ably
//
//  Created by Yavor Georgiev on 23.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import ably
import ably.Private
import Foundation
import SwiftyJSON

extension ARTMessage {
    public override func isEqual(object: AnyObject?) -> Bool {
        if let other = object as? ARTMessage {
            return self.name == other.name && self.payload == other.payload
        }
        
        return super.isEqual(object)
    }
}

extension ARTPayload {
    public override func isEqual(object: AnyObject?) -> Bool {
        if let other = object as? ARTPayload {
            if let selfPayload = self.payload as? NSObject {
                if let otherPayload = other.payload as? NSObject {
                    return selfPayload == otherPayload && self.encoding == other.encoding
                }
            }
        }
        
        return super.isEqual(object)
    }
}

extension NSObject {
    var toBase64: String {
        return (try? NSJSONSerialization.dataWithJSONObject(self, options: NSJSONWritingOptions(rawValue: 0)).base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))) ?? ""
    }
}

extension NSData {
    override var toBase64: String {
        return self.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
}

extension JSON {
    var asArray: NSArray? {
        return object as? NSArray
    }

    var asDictionary: NSDictionary? {
        return object as? NSDictionary
    }
}

class RestChannel: QuickSpec {
    override func spec() {
        var client: ARTRest!
        var channel: ARTChannel! //ARTRestChannel
        var mockExecutor: MockHTTPExecutor!

        beforeEach {
            client = ARTRest(options: AblyTests.setupOptions(AblyTests.jsonRestOptions))
            channel = client.channels.get(NSProcessInfo.processInfo().globallyUniqueString)
            mockExecutor = MockHTTPExecutor()
        }
        
        // RSL1
        describe("publish") {
            let name = "foo"
            let data = "bar"
            
            // RSL1b
            context("with name and data arguments") {
                it("publishes the message and invokes callback with success") {
                    var publishError: NSError? = NSError(domain: "", code: -1, userInfo: nil)
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(data, name: name) { error in
                        publishError = error
                        try! channel.history(nil) { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(equal(name), timeout: testTimeout)
                    expect(publishedMessage?.payload.payload as? String).toEventually(equal(data), timeout: testTimeout)
                }
            }
            
            // RSL1b, RSL1e
            context("with name only") {
                it("publishes the message and invokes callback with success") {
                    var publishError: NSError? = NSError(domain: "", code: -1, userInfo: nil)
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(nil, name: name) { error in
                        publishError = error
                        try! channel.history(nil) { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(equal(name), timeout: testTimeout)
                    expect(publishedMessage?.payload.payload).toEventually(beNil(), timeout: testTimeout)
                }
            }
            
            // RSL1b, RSL1e
            context("with data only") {
                it("publishes the message and invokes callback with success") {
                    var publishError: NSError? = NSError(domain: "", code: -1, userInfo: nil)
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(data) { error in
                        publishError = error
                        try! channel.history(nil) { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.payload.payload as? String).toEventually(equal(data), timeout: testTimeout)
                }
            }
            
            // RSL1b, RSL1e
            context("with neither name nor data") {
                it("publishes the message and invokes callback with success") {
                    var publishError: NSError? = NSError(domain: "", code: -1, userInfo: nil)
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(nil) { error in
                        publishError = error
                        try! channel.history(nil) { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.payload.payload).toEventually(beNil(), timeout: testTimeout)
                }
            }
            
            context("with a Message object") {
                it("publishes the message and invokes callback with success") {
                    var publishError: NSError? = NSError(domain: "", code: -1, userInfo: nil)
                    var publishedMessage: ARTMessage?
                    
                    channel.publishMessage(ARTMessage(data:data, name: name)) { error in
                        publishError = error
                        try! channel.history(nil) { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.payload.payload).toEventually(beNil(), timeout: testTimeout)
                }
            }
            
            // RSL1c
            context("with an array of Message objects") {
                it("publishes the messages and invokes callback with success") {
                    var publishError: NSError? = NSError(domain: "", code: -1, userInfo: nil)
                    var publishedMessages: [ARTMessage] = []

                    let messages = [
                        ARTMessage(data: "foo", name: "bar"),
                        ARTMessage(data: "baz", name: "bat")
                    ]
                    channel.publishMessages(messages) { error in
                        publishError = error
                        try! channel.history(nil) { result, _ in
                            if let items = result?.items as? [ARTMessage] {
                                publishedMessages.appendContentsOf(items)
                            }
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessages.count).toEventually(equal(messages.count), timeout: testTimeout)
                    expect(publishedMessages).toEventually(contain(messages.first), timeout: testTimeout)
                    expect(publishedMessages).toEventually(contain(messages.last), timeout: testTimeout)
                }
            }
        }
        
        // RSL3, RSP1
        describe("presence") {
            let presenceFixtures = appSetupJson["post_apps"]["channels"][0]["presence"]
            
            // RSP3
            context("get") {
                it("should return presence fixture data") {
                    let channel = client.channels.get("persisted:presence_fixtures")
                    var presenceMessages: [ARTPresenceMessage] = []

                    channel.presence().get() { result, _ in
                        if let items = result?.items as? [ARTPresenceMessage] {
                            presenceMessages.appendContentsOf(items)
                        }
                    }

                    expect(presenceMessages.count).toEventually(equal(presenceFixtures.count), timeout: testTimeout)
                    for message in presenceMessages {
                        
                        let fixtureMessage = presenceFixtures.filter({ (key, value) -> Bool in
                            return message.clientId == value["clientId"].stringValue
                        }).first!.1
                        
                        expect(message.content()).toNot(beNil())
                        expect(message.action).to(equal(ARTPresenceAction.Present))

                        // skip the encrypted message for now
                        if message.payload.encoding.rangeOfString("cipher") == nil {
                            expect(message.content() as? NSObject).to(equal(fixtureMessage["data"].object as? NSObject))
                        }
                    }
                }
            }
        }

        describe("message encoding") {

            struct TestCase {
                let value: AnyObject?
                let expected: JSON
            }

            let text = "John"
            let integer = "5"
            let decimal = "65.33"
            let dictionary = ["number":3, "name":"John"]
            let array = ["John", "Mary"]
            let data = NSString(string: "123456").dataUsingEncoding(NSUTF8StringEncoding)!

            // RSL4a
            it("payloads should be binary, strings, or objects capable of JSON representation") {
                let validCases = [
                    TestCase(value: nil, expected: JSON([:])),
                    TestCase(value: text, expected: JSON(["data": text])),
                    TestCase(value: integer, expected: JSON(["data": integer])),
                    TestCase(value: decimal, expected: JSON(["data": decimal])),
                    TestCase(value: dictionary, expected: JSON(["data": dictionary, "encoding": "json"])),
                    TestCase(value: array, expected: JSON(["data": array, "encoding": "json"])),
                    TestCase(value: data, expected: JSON(["data": data.toBase64, "encoding": "base64"])),
                ]

                client.httpExecutor = mockExecutor

                validCases.forEach { caseTest in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(caseTest.value, callback: { error in
                            expect(error).to(beNil())

                            if let request = mockExecutor.requests.last,
                                let http = request.HTTPBody {
                                    expect(caseTest.expected).to(equal(JSON(data: http)))
                            }
                            done()
                        })
                    }
                }

                let invalidCases = [5, 56.33, NSDate()]

                invalidCases.forEach { caseItem in
                    waitUntil(timeout: testTimeout) { done in
                        expect { channel.publish(caseItem, callback: nil) }.to(raiseException())
                        done()
                    }
                }
            }

            // RSL4b
            it("encoding attribute should represent the encoding(s) applied in right to left") {
                let encodingCases = [
                    TestCase(value: text, expected: nil),
                    TestCase(value: dictionary, expected: "json"),
                    TestCase(value: array, expected: "json"),
                    TestCase(value: data, expected: "base64"),
                ]

                client.httpExecutor = mockExecutor

                encodingCases.forEach { caseItem in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(caseItem.value, callback: { error in
                            expect(error).to(beNil())

                            if let request = mockExecutor.requests.last,
                               let http = request.HTTPBody {
                                expect(JSON(data: http)["encoding"]).to(equal(caseItem.expected))
                            }
                            done()
                        })
                    }
                }
            }

            context("json") {
                // RSL4d1
                it("binary payload should be encoded as Base64 and represented as a JSON string") {
                    client.httpExecutor = mockExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(data, callback: { error in
                            expect(error).to(beNil())

                            if let request = mockExecutor.requests.last, let http = request.HTTPBody {
                                // Binary
                                let json = JSON(data: http)
                                expect(json["data"].string).to(equal(data.toBase64))
                                expect(json["encoding"]).to(equal("base64"))
                            }
                            else {
                                XCTFail("No request or HTTP body found")
                            }
                            done()
                        })
                    }
                }

                // RSL4d
                it("string payload should be represented as a JSON string") {
                    client.httpExecutor = mockExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(text, callback: { error in
                            expect(error).to(beNil())

                            if let request = mockExecutor.requests.last, let http = request.HTTPBody {
                                // String (UTF-8)
                                let json = JSON(data: http)
                                expect(json["data"].string).to(equal(text))
                                expect(json["encoding"].string).to(beNil())
                            }
                            else {
                                XCTFail("No request or HTTP body found")
                            }
                            done()
                        })
                    }
                }

                // RSL4d3
                context("json payload should be stringified either") {

                    it("as a JSON Array") {
                        client.httpExecutor = mockExecutor
                        // JSON Array
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(array, callback: { error in
                                expect(error).to(beNil())

                                if let request = mockExecutor.requests.last, let http = request.HTTPBody {
                                    // Array
                                    let json = JSON(data: http)
                                    expect(json["data"].asArray).to(equal(array))
                                    expect(json["encoding"].string).to(equal("json"))
                                }
                                else {
                                    XCTFail("No request or HTTP body found")
                                }
                                done()
                            })
                        }
                    }

                    it("as a JSON Object") {
                        client.httpExecutor = mockExecutor
                        // JSON Object
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(dictionary, callback: { error in
                                expect(error).to(beNil())

                                if let request = mockExecutor.requests.last, let http = request.HTTPBody {
                                    // Dictionary
                                    let json = JSON(data: http)
                                    expect(json["data"].asDictionary).to(equal(dictionary))
                                    expect(json["encoding"].string).to(equal("json"))
                                }
                                else {
                                    XCTFail("No request or HTTP body found")
                                }
                                done()
                            })
                        }
                    }

                }

                // RSL4d4
                it("messages received should be decoded based on the encoding field") {
                    let cases = [text, integer, decimal, dictionary, array, data]

                    cases.forEach { caseTest in
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(caseTest, callback: { error in
                                expect(error).to(beNil())
                                done()
                            })
                        }
                    }

                    var totalReceived = 0
                    try! channel.history(nil) { result, error in
                        expect(error).to(beNil())
                        expect(result).toNot(beNil())
                        expect(result?.hasNext).to(beFalse())

                        for (index, item) in (result?.items.reverse().enumerate())! {
                            totalReceived++

                            switch (item as? ARTMessage)?.payload.payload {
                            case let value as NSDictionary:
                                expect(value).to(equal(cases[index]))
                                break
                            case let value as NSArray:
                                expect(value).to(equal(cases[index]))
                                break
                            case let value as NSData:
                                expect(value).to(equal(cases[index]))
                                break
                            case let value as NSString:
                                expect(value).to(equal(cases[index]))
                                break
                            default:
                                XCTFail("Payload with unknown format")
                                break
                            }
                        }
                    }
                    expect(totalReceived).toEventually(equal(cases.count), timeout: testTimeout)
                }
            }
        }
    }
}
