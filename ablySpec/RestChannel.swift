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

class RestChannel: QuickSpec {
    override func spec() {
        var client: ARTRest!
        var channel: ARTChannel! //ARTRestChannel
        
        beforeEach {
            client = ARTRest(options: AblyTests.setupOptions(AblyTests.jsonRestOptions))
            channel = client.channels.get(NSProcessInfo.processInfo().globallyUniqueString)
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
                        if message.payload.encoding?.rangeOfString("cipher") == nil {
                            expect(message.content() as? NSObject).to(equal(fixtureMessage["data"].object as? NSObject))
                        }
                    }
                }
            }
        }
    }
}
