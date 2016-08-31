//
//  RestClientChannel.swift
//  ably
//
//  Created by Yavor Georgiev on 23.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

import AblyRealtime
import Nimble
import Quick
import Foundation
import SwiftyJSON

class RestClientChannel: QuickSpec {
    override func spec() {
        var client: ARTRest!
        var channel: ARTChannel! //ARTRestChannel
        var testHTTPExecutor: TestProxyHTTPExecutor!

        beforeEach {
            client = ARTRest(options: AblyTests.setupOptions(AblyTests.jsonRestOptions))
            channel = client.channels.get(NSProcessInfo.processInfo().globallyUniqueString)
            testHTTPExecutor = TestProxyHTTPExecutor()
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
                    client.httpExecutor = testHTTPExecutor

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
                    expect(testHTTPExecutor.requests.count).to(equal(1))
                }
            }

            // RSL1f
            context("Unidentified clients using Basic Auth") {
                // RSL1f1
                it("should publish message with the provided clientId") {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish([ARTMessage(name: nil, data: "message", clientId: "tester")]) { error in
                            expect(error).to(beNil())
                            expect(client.auth.method).to(equal(ARTAuthMethod.Basic))
                            channel.history { page, error in
                                expect(error).to(beNil())
                                let item = page!.items[0] as! ARTMessage
                                expect(item.clientId).to(equal("tester"))
                                done()
                            }
                        }
                    }
                }
            }

            // RSL1g
            context("Identified clients with a clientId") {

                // RSL1g1
                context("when publishing a Message with the clientId attribute set to null") {

                    // RSL1g1a, RSL1g1b
                    it("should be unnecessary to set clientId of the Message before publishing") {
                        let options = AblyTests.commonAppSetup()
                        options.clientId = "john"
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        waitUntil(timeout: testTimeout) { done in
                            let message = ARTMessage(name: nil, data: "message")
                            expect(message.clientId).to(beNil())

                            channel.publish([message]) { error in
                                expect(error).to(beNil())
                                channel.history { page, error in
                                    expect(error).to(beNil())
                                    let item = page!.items[0] as! ARTMessage
                                    expect(item.clientId).to(equal("john"))
                                    done()
                                }
                            }
                        }
                    }

                }

                // RSL1g2
                it("when publishing a Message with the clientId attribute set to the identified client’s clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    waitUntil(timeout: testTimeout) { done in
                        let message = ARTMessage(name: nil, data: "message", clientId: options.clientId!)
                        channel.publish([message]) { error in
                            expect(error).to(beNil())
                            channel.history { page, error in
                                expect(error).to(beNil())
                                let item = page!.items[0] as! ARTMessage
                                expect(item.clientId).to(equal("john"))
                                done()
                            }
                        }
                    }
                }

                // RSL1g3
                it("when publishing a Message with a different clientId attribute value to the identified client’s clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRest(options: options)
                    client.httpExecutor = testHTTPExecutor
                    let channel = client.channels.get("test")

                    // Reject before the message is sent to the server
                    let hook = channel.testSuite_injectIntoMethodBefore(#selector(ARTChannel.publish(_:callback:))) {
                        testHTTPExecutor.http = nil
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let message = ARTMessage(name: nil, data: "message", clientId: "tester")
                        channel.publish([message]) { error in
                            expect(error!.code).to(equal(Int(ARTState.MismatchedClientId.rawValue)))
                            done()
                        }
                    }

                    hook.remove()
                    testHTTPExecutor.http = ARTHttp()

                    // Remains available
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message") { error in
                            expect(error).to(beNil())
                            done()
                        }
                    }
                }

                // RSL1g4
                pending("when publishing a Message with an explicit clientId that is incompatible with the identified client’s clientId") {
                    let options = AblyTests.commonAppSetup()
                    options.clientId = "john"
                    let client = ARTRest(options: options)
                    client.httpExecutor = testHTTPExecutor
                    let channel = client.channels.get("test")

                    // Reject before the message is sent to the server
                    channel.testSuite_injectIntoMethodBefore(#selector(ARTChannel.publish(_:callback:))) {
                        testHTTPExecutor.http = nil
                    }

                    waitUntil(timeout: testTimeout) { done in
                        let message = ARTMessage(name: nil, data: "message", clientId: "tester")
                        channel.publish([message]) { error in
                            expect(error!.code).to(equal(Int(ARTState.MismatchedClientId.rawValue)))

                            testHTTPExecutor.http = ARTHttp()
                            channel.history { page, error in
                                expect(error).to(beNil())
                                expect(page!.items).to(haveCount(0))
                                done()
                            }
                        }
                    }
                }

            }

            // RSL1h
            it("should provide an optional argument that allows the clientId value to be specified") {
                let options = AblyTests.commonAppSetup()
                options.clientId = "john"
                let client = ARTRest(options: options)
                let channel = client.channels.get("test")
                waitUntil(timeout: testTimeout) { done in
                    channel.publish("name", data: "some data", clientId: "tester") { error in
                        expect(error!.message).to(contain("invalid clientId"))
                        done()
                    }
                }
            }

        }

        // RSL2
        describe("history") {

            // RSL2b
            context("query arguments") {

                // RSL2b1
                it("start and end should filter messages between those two times") {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.direction) == ARTQueryDirection.Backwards
                    expect(query.limit) == 100

                    query.start = NSDate()

                    let messages = [
                        ARTMessage(name: nil, data: "message1"),
                        ARTMessage(name: nil, data: "message2")
                    ]
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { _ in
                            query.end = NSDate()
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: "message3") { _ in
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        try! channel.history(query) { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("PaginatedResult is empty"); done()
                                return
                            }
                            expect(result.hasNext).to(beFalse())
                            expect(result.isLast).to(beTrue())
                            guard let items = result.items as? [ARTMessage] where result.items.count == 2 else {
                                fail("PaginatedResult has no items"); done()
                                return
                            }
                            let messageItems = items.flatMap({ $0.data as? String })
                            expect(messageItems.first).to(equal("message2"))
                            expect(messageItems.last).to(equal("message1"))
                            done()
                        }
                    }
                }

                // RSL2b1
                it("start must be equal to or less than end and is unaffected by the request direction") {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    query.direction = .Backwards
                    query.end = NSDate()
                    query.start = query.end!.dateByAddingTimeInterval(10.0)

                    expect { try channel.history(query) { _, _ in } }.to(throwError { (error: ErrorType) in
                        expect(error._code).to(equal(ARTDataQueryError.TimestampRange.rawValue))
                    })

                    query.direction = .Forwards

                    expect { try channel.history(query) { _, _ in } }.to(throwError { (error: ErrorType) in
                        expect(error._code).to(equal(ARTDataQueryError.TimestampRange.rawValue))
                    })
                }

                // RSL2b2
                it("direction backwards or forwards") {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.direction) == ARTQueryDirection.Backwards
                    query.direction = .Forwards

                    let messages = [
                        ARTMessage(name: nil, data: "message1"),
                        ARTMessage(name: nil, data: "message2")
                    ]
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { _ in
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        try! channel.history(query) { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("PaginatedResult is empty"); done()
                                return
                            }
                            expect(result.hasNext).to(beFalse())
                            expect(result.isLast).to(beTrue())
                            guard let items = result.items as? [ARTMessage] where result.items.count == 2 else {
                                fail("PaginatedResult has no items"); done()
                                return
                            }
                            let messageItems = items.flatMap({ $0.data as? String })
                            expect(messageItems.first).to(equal("message1"))
                            expect(messageItems.last).to(equal("message2"))
                            done()
                        }
                    }
                }

                // RSL2b3
                it("limit items result") {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.limit) == 100
                    query.limit = 2

                    let messages = (1...10).flatMap{ ARTMessage(name: nil, data: "message\($0)") }
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(messages) { _ in
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        try! channel.history(query) { result, error in
                            expect(error).to(beNil())
                            guard let result = result else {
                                fail("PaginatedResult is empty"); done()
                                return
                            }
                            expect(result.hasNext).to(beTrue())
                            expect(result.isLast).to(beFalse())
                            guard let items = result.items as? [ARTMessage] where result.items.count == 2 else {
                                fail("PaginatedResult has no items"); done()
                                return
                            }
                            let messageItems = items.flatMap({ $0.data as? String })
                            expect(messageItems.first).to(equal("message10"))
                            expect(messageItems.last).to(equal("message9"))
                            done()
                        }
                    }
                }

                // RSL2b3
                it("limit supports up to 1000 items") {
                    let client = ARTRest(options: AblyTests.commonAppSetup())
                    let channel = client.channels.get("test")

                    let query = ARTDataQuery()
                    expect(query.limit) == 100

                    query.limit = 1001
                    expect{ try channel.history(query, callback: { _ in }) }.to(throwError())

                    query.limit = 1000
                    expect{ try channel.history(query, callback: { _ in }) }.toNot(throwError())
                }

            }

        }

        // RSL3, RSP1
        describe("presence") {
            let presenceFixtures = appSetupJson["post_apps"]["channels"][0]["presence"]

            // RSP3
            context("get") {
                it("should return presence fixture data") {
                    let originalARTChannels_getChannelNamePrefix = ARTChannels_getChannelNamePrefix
                    defer { ARTChannels_getChannelNamePrefix = originalARTChannels_getChannelNamePrefix }
                    ARTChannels_getChannelNamePrefix = nil // Force that channel name is not changed.

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
                    TestCase(value: dictionary, expected: JSON(["data": JSON(dictionary).rawString(0, options: NSJSONWritingOptions.init(rawValue: 0))!, "encoding": "json"])),
                    TestCase(value: array, expected: JSON(["data": JSON(array).rawString(0, options: NSJSONWritingOptions.init(rawValue: 0))!, "encoding": "json"])),
                    TestCase(value: binaryData, expected: JSON(["data": binaryData.toBase64, "encoding": "base64"])),
                ]

                client.httpExecutor = testHTTPExecutor

                validCases.forEach { caseTest in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseTest.value) { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.HTTPBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            expect(AblyTests.msgpackToJSON(httpBody)).to(equal(caseTest.expected))
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

                client.httpExecutor = testHTTPExecutor

                encodingCases.forEach { caseItem in
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: caseItem.value, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.HTTPBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            expect(AblyTests.msgpackToJSON(httpBody)["encoding"]).to(equal(caseItem.expected))
                            done()
                        })
                    }
                }
            }

            context("json") {
                // RSL4d1
                it("binary payload should be encoded as Base64 and represented as a JSON string") {
                    client.httpExecutor = testHTTPExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: binaryData, callback: { error in
                            expect(error).to(beNil())
                            guard let httpBody = testHTTPExecutor.requests.last!.HTTPBody else {
                                XCTFail("HTTPBody is nil");
                                done(); return
                            }
                            // Binary
                            let json = AblyTests.msgpackToJSON(httpBody)
                            expect(json["data"].string).to(equal(binaryData.toBase64))
                            expect(json["encoding"]).to(equal("base64"))
                            done()
                        })
                    }
                }

                // RSL4d
                it("string payload should be represented as a JSON string") {
                    client.httpExecutor = testHTTPExecutor
                    waitUntil(timeout: testTimeout) { done in
                        channel.publish(nil, data: text, callback: { error in
                            expect(error).to(beNil())

                            if let request = testHTTPExecutor.requests.last, let http = request.HTTPBody {
                                // String (UTF-8)
                                let json = AblyTests.msgpackToJSON(http)
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
                        client.httpExecutor = testHTTPExecutor
                        // JSON Array
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: array, callback: { error in
                                expect(error).to(beNil())

                                if let request = testHTTPExecutor.requests.last, let http = request.HTTPBody {
                                    // Array
                                    let json = AblyTests.msgpackToJSON(http)
                                    print(json.rawString())
                                    expect(JSON(data: json["data"].stringValue.dataUsingEncoding(NSUTF8StringEncoding)!).asArray).to(equal(array))
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
                        client.httpExecutor = testHTTPExecutor
                        // JSON Object
                        waitUntil(timeout: testTimeout) { done in
                            channel.publish(nil, data: dictionary, callback: { error in
                                expect(error).to(beNil())

                                if let request = testHTTPExecutor.requests.last, let http = request.HTTPBody {
                                    // Dictionary
                                    let json = AblyTests.msgpackToJSON(http)
                                    expect(JSON(data: json["data"].stringValue.dataUsingEncoding(NSUTF8StringEncoding)!).asDictionary).to(equal(dictionary))
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
                            totalReceived += 1

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
            it("should deliver with encoding attribute set indicating the residual encoding and error should be emitted") {
                let options = AblyTests.commonAppSetup()
                options.logHandler = ARTLog(capturingOutput: true)
                let client = ARTRest(options: options)
                let channelOptions = ARTChannelOptions(cipher: ["key":ARTCrypto.generateRandomKey()])
                let channel = client.channels.get("test", options: channelOptions)
                client.httpExecutor = testHTTPExecutor

                let expectedMessage = ["something":1]
                let expectedData = try! NSJSONSerialization.dataWithJSONObject(expectedMessage, options: NSJSONWritingOptions(rawValue: 0))

                testHTTPExecutor.beforeProcessingDataResponse = { data in
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
                        expect(line).to(contain("Failed to decode data: unknown encoding: 'invalid'"))
                        done()
                    }
                }
            }

        }

    }
}
