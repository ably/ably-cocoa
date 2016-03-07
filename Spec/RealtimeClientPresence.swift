//
//  RealtimeClientPresence.swift
//  Ably
//
//  Created by Ricardo Pereira on 07/03/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble

func addRandomMemberToChannel(channelName: String, options: ARTClientOptions, done: ()->()) -> [ARTRealtime] {
    let client = ARTRealtime(options: options)
    let channel = client.channels.get(channelName)
    channel.attach() { _ in
        channel.presence.enterClient(AblyTests.newRandomString(), data: nil)
        done()
    }
    return [client]
}

class RealtimeClientPresence: QuickSpec {
    override func spec() {
        describe("Presence") {



        }
    }
}
