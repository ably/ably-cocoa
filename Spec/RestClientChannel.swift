//
//  RestClientChannel.swift
//  ably
//
//  Created by Yavor Georgiev on 23.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import Nimble
import Quick
import Foundation
import SwiftyJSON

class RestClientChannel: QuickSpec {
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
                    var publishError: ARTErrorInfo? = ARTErrorInfo.createWithNSError(NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(name, data: data) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(equal(name), timeout: testTimeout)
                    expect(publishedMessage?.data as? String).toEventually(equal(data), timeout: testTimeout)
                }
            }
            
            // RSL1b, RSL1e
            context("with name only") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.createWithNSError(NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(name, data: nil) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(equal(name), timeout: testTimeout)
                    expect(publishedMessage?.data).toEventually(beNil(), timeout: testTimeout)
                }
            }
            
            // RSL1b, RSL1e
            context("with data only") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.createWithNSError(NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(nil, data: data) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.data as? String).toEventually(equal(data), timeout: testTimeout)
                }
            }
            
            // RSL1b, RSL1e
            context("with neither name nor data") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.createWithNSError(NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?
                    
                    channel.publish(nil, data: nil) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.data).toEventually(beNil(), timeout: testTimeout)
                }
            }
            
            context("with a Message object") {
                it("publishes the message and invokes callback with success") {
                    var publishError: ARTErrorInfo? = ARTErrorInfo.createWithNSError(NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessage: ARTMessage?
                    
                    channel.publish([ARTMessage(name: name, data: data)]) { error in
                        publishError = error
                        channel.history { result, _ in
                            publishedMessage = result?.items.first as? ARTMessage
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.name).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessage?.data).toEventually(beNil(), timeout: testTimeout)
                }
            }
            
            // RSL1c
            context("with an array of Message objects") {
                it("publishes the messages in a single request and invokes callback with success") {
                    let oldExecutor = client.httpExecutor
                    defer { client.httpExecutor = oldExecutor}
                    client.httpExecutor = mockExecutor

                    var publishError: ARTErrorInfo? = ARTErrorInfo.createWithNSError(NSError(domain: "", code: -1, userInfo: nil))
                    var publishedMessages: [ARTMessage] = []

                    let messages = [
                        ARTMessage(name: "bar", data: "foo"),
                        ARTMessage(name: "bat", data: "baz")
                    ]
                    channel.publish(messages) { error in
                        publishError = error
                        client.httpExecutor = oldExecutor
                        channel.history { result, _ in
                            if let items = result?.items as? [ARTMessage] {
                                publishedMessages.appendContentsOf(items)
                            }
                        }
                    }
                    
                    expect(publishError).toEventually(beNil(), timeout: testTimeout)
                    expect(publishedMessages.count).toEventually(equal(messages.count), timeout: testTimeout)
                    for (i, publishedMessage) in publishedMessages.reverse().enumerate() {
                        expect(publishedMessage.data as? NSObject).to(equal(messages[i].data as? NSObject))
                        expect(publishedMessage.name).to(equal(messages[i].name))
                    }
                    expect(mockExecutor.requests.count).to(equal(1))
                }
            }
        }
        
        // RSL3, RSP1
        describe("presence") {
            let presenceFixtures = appSetupJson["post_apps"]["channels"][0]["presence"]
            
            // RSP3
            context("get") {
                it("should return presence fixture data") {
                    let key = appSetupJson["cipher"]["key"].string!
                    let cipherParams = ARTCipherParams.init(
                        algorithm: appSetupJson["cipher"]["algorithm"].string!,
                        key: key,
                        iv: NSData(base64EncodedString: appSetupJson["cipher"]["iv"].string!, options: NSDataBase64DecodingOptions.init(rawValue: 0))!
                    )
                    let channel = client.channels.get("persisted:presence_fixtures", options:ARTChannelOptions.init(cipher: cipherParams))
                    var presenceMessages: [ARTPresenceMessage] = []

                    channel.presence.get() { result, _ in
                        if let items = result?.items as? [ARTPresenceMessage] {
                            presenceMessages.appendContentsOf(items)
                        }
                    }

                    expect(presenceMessages.count).toEventually(equal(presenceFixtures.count), timeout: testTimeout)
                    for message in presenceMessages {
                        let fixtureMessage = presenceFixtures.filter({ (key, value) -> Bool in
                            return message.clientId == value["clientId"].stringValue
                        }).first!.1
                        
                        expect(message.data).toNot(beNil())
                        expect(message.action).to(equal(ARTPresenceAction.Present))

                        let encodedFixture = channel.dataEncoder.decode(
                            fixtureMessage["data"].object,
                            encoding:fixtureMessage.asDictionary!["encoding"] as? String
                        )
                        expect(message.data as? NSObject).to(equal(encodedFixture.data as? NSObject));
                    }
                }
            }
        }

        // RSL4
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
            let binaryData = NSString(string: "123456").dataUsingEncoding(NSUTF8StringEncoding)!

            // RSL4a
            it("payloads should be binary, strings, or objects capable of JSON representation") {
                let validCases = [
                    TestCase(value: nil, expected: JSON([:])),
                    TestCase(value: text, expected: JSON(["data": text])),
                    TestCase(value: integer, expected: JSON(["data": integer])),
                    TestCase(value: decimal, expected: JSON(["data": decimal])),
                    TestCase(value: dictionary, expected: JSON(["data": dictionary, "encoding": "json"])),
                    TestCase(value: array, expected: JSON(["data": array, "encoding": "json"])),
                    TestCase(value: binaryData, expected: JSON(["data": binaryData.toBase64, "encoding": "base64"])),
                ]

                client.httpExecutor = mockExecutor

                validCases.forEach { caseTest in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseTest.value) { error in
                            expect(error).to(beNil())
                            guard let httpBody = mockExecutor.requests.last!.HTTPBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            expect(JSON(data: httpBody)).to(equal(caseTest.expected))
                            done()
                        }
                    }
                }

                let invalidCases = [5, 56.33, NSDate()]

                invalidCases.forEach { caseItem in
                    waitUntil(timeout: testTimeout) { done in
                        expect { channel.publish(nil, data: caseItem, callback: nil) }.to(raiseException(named: NSInvalidArgumentException))
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
                    TestCase(value: binaryData, expected: "base64"),
                ]

                client.httpExecutor = mockExecutor

                encodingCases.forEach { caseItem in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseItem.value, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = mockExecutor.requests.last!.HTTPBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            expect(JSON(data: httpBody)["encoding"]).to(equal(caseItem.expected))
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
                        channel.publish(nil, data: binaryData, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = mockExecutor.requests.last!.HTTPBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            // Binary
                            let json = JSON(data: httpBody)
                            expect(json["data"].string).to(equal(binaryData.toBase64))
                            expect(json["encoding"]).to(equal("base64"))
                            done()
                        })
                    }
                }

                // RSL4d
                it("string payload should be represented as a JSON string") {
                    client.httpExecutor = mockExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: text, callback: { error in
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
                            channel.publish(nil, data: array, callback: { error in
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
                            channel.publish(nil, data: dictionary, callback: { error in
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
                    let cases = [text, integer, decimal, dictionary, array, binaryData]

                    cases.forEach { caseTest in
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: caseTest, callback: { error in
                                expect(error).to(beNil())
                                done()
                            })
                        }
                    }

                    var totalReceived = 0
                    channel.history { result, error in
                        expect(error).to(beNil())
                        guard let result = result else {
                            XCTFail("Result is nil")
                            return
                        }
                        expect(result.hasNext).to(beFalse())

                        for (index, item) in (result.items.reverse().enumerate()) {
                            totalReceived++

                            switch (item as? ARTMessage)?.data {
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

        // RSL6
        describe("message decoding") {

            // RSL6b
            it("should deliver with a binary payload when the payload was successfully decoded but it could not be decrypted") {
                let options = AblyTests.commonAppSetup()
                let clientEncrypted = ARTRest(options: options)

                let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()])
                let channelEncrypted = clientEncrypted.channels.get("test", options: channelOptions)

                let expectedMessage = ["something":1]

                waitUntil(timeout: testTimeout) { done in
                    channelEncrypted.publish(nil, data: expectedMessage) { error in
                        done()
                    }
                }

                let client = ARTRest(options: options)
                let channel = client.channels.get("test")

                waitUntil(timeout: testTimeout) { done in
                    channel.history { result, error in
                        let message = (result!.items as! [ARTMessage])[0]
                        expect(message.data is NSData).to(beTrue())
                        expect(message.encoding).to(equal("json/utf-8/cipher+aes-256-cbc"))
                        done()
                    }
                }
            }

            // RSL6b
            pending("should deliver with encoding attribute set indicating the residual encoding and error should be emitted") {
                let options = AblyTests.commonAppSetup()
                options.logHandler = ARTLog(capturingOutput: true)
                let client = ARTRest(options: options)
                let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()])
                let channel = client.channels.get("test", options: channelOptions)
                client.httpExecutor = mockExecutor

                let expectedMessage = ["something":1]
                let expectedData = try! NSJSONSerialization.dataWithJSONObject(expectedMessage, options: NSJSONWritingOptions(rawValue: 0))

                mockExecutor.beforeProcessingDataResponse = { data in
                    let dataStr = String(data: data!, encoding: NSUTF8StringEncoding)!
                    return dataStr.replace("json/utf-8", withString: "invalid").dataUsingEncoding(NSUTF8StringEncoding)!
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.publish(nil, data: expectedMessage) { error in
                        done()
                    }
                }

                waitUntil(timeout: testTimeout) { done in
                    channel.history { result, error in
                        let message = (result!.items as! [ARTMessage])[0]
                        expect(message.data as? NSData).to(equal(expectedData))
                        expect(message.encoding).to(equal("invalid"))

                        let logs = options.logHandler.captured
                        let line = logs.reduce("") { $0 + "; " + $1.toString() } //Reduce in one line
                        expect(line).to(contain("ERROR: Failed to decode data: unknown encoding: 'invalid'"))
                        done()
                    }
                }
            }

        }

    }
}
