//
//  RealtimeClientChannels.swift
//  ably
//
//  Created by Ricardo Pereira on 01/02/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble

class RealtimeClientChannels: QuickSpec {
    override func spec() {
        describe("Channels") {

            // RTS2
            it("should exist methods to check if a channel exists or iterate through the existing channels") {
                let client = ARTRealtime(options: AblyTests.commonAppSetup())
                defer { client.close() }
                var disposable = [ARTChannel]()

                disposable.append(client.channel("test1"))
                disposable.append(client.channel("test2"))
                disposable.append(client.channel("test3"))

                expect(client.channels()["test2"]).toNot(beNil())
                expect(client.channels().contains{ (name, _) in name == "test2" }).to(beTrue())
                expect(client.channels().contains{ $0.0 == "test2" }).to(beTrue()) //Same as last one
                expect(client.channels()["testX"]).to(beNil())

                client.channels().forEach { name, channel in
                    expect(disposable.contains(channel)).to(beTrue())
                }

                for (_, channel) in client.channels() {
                    expect(disposable.contains(channel)).to(beTrue())
                }
            }

        }
    }
}
