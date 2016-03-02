//
//  RealtimeClientChannels.swift
//  ably
//
//  Created by Ricardo Pereira on 01/02/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble

// Swift isn't yet smart enough to do this automatically when bridging Objective-C APIs
extension ARTRealtimeChannels: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

class RealtimeClientChannels: QuickSpec {
    override func spec() {
        describe("Channels") {

            // RTS2
            it("should exist methods to check if a channel exists or iterate through the existing channels") {
                let client = ARTRealtime(options: AblyTests.commonAppSetup())
                defer { client.close() }
                var disposable = [ARTRealtimeChannel]()

                disposable.append(client.channels.get("test1"))
                disposable.append(client.channels.get("test2"))
                disposable.append(client.channels.get("test3"))

                expect(client.channels.get("test2")).toNot(beNil())
                expect(client.channels.exists("test2")).to(beTrue())
                expect(client.channels.exists("testX")).to(beFalse())

                for channel in client.channels {
                    expect(disposable.contains(channel as! ARTRealtimeChannel)).to(beTrue())
                }
            }

        }
    }
}
