//
//  ReadmeExamples.swift
//
//
//  Created by Toni Cárdenas on 9/2/16.
//
//

import Ably
import Foundation
import Quick
import Nimble

// This file is to be kept in sync with the examples in README.md, to make sure they are kept valid.

class ReadmeExamples : QuickSpec {
    override func spec() {

        it("testMakeKeyInstance") {
            let client = ARTRealtime(key: "xxxx:xxxx")
            client.connection.close()
        }

        it("testMakeTokenInstance") {
            let client = ARTRealtime(token: "xxxx")
            client.connection.close()
        }

        it("testListenToConnectionStateChanges") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRealtime(options: options)
            defer { client.close() }

            client.connection.on { stateChange in
                switch stateChange.current {
                case .connected:
                    print("connected!")
                case .failed:
                    print("failed! \(String(describing: stateChange.reason))")
                default:
                    break
                }
            }
        }

        it("testNoAutoConnect") {
            let options = ARTClientOptions(key: "xxxx:xxxx")
            options.autoConnect = false
            let client = ARTRealtime(options: options)
            client.connection.connect()
            client.connection.close()
        }

        it("testSubscribeAndPublishingToChannel") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRealtime(options: options)
            defer { client.close() }

            let channel = client.channels.get("test")

            channel.subscribe { message in
                print(message.name as Any)
                print(message.data as Any)
            }

            channel.subscribe("myEvent") { message in
                print(message.name as Any)
                print(message.data as Any)
            }

            channel.publish("greeting", data: "Hello World!")
        }

        it("testQueryingTheHistory") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRealtime(options: options)
            defer { client.close() }

            let channel = client.channels.get("test")

            channel.history { messagesPage, error in
                let messagesPage = messagesPage!
                print(messagesPage.items)
                print(messagesPage.items.first as Any)
                print(messagesPage.items.first?.data as Any) // payload for the message
                print(messagesPage.items.count) // number of messages in the current page of history
                messagesPage.next { nextPage, error in
                    // retrieved the next page in nextPage
                }
                print(messagesPage.hasNext) // true, there are more pages
            }
        }

        it("testPresenceOnAChannel") {
            let options = AblyTests.clientOptions(requestToken: true)
            options.clientId = "foo"
            let client = ARTRealtime(options: options)
            defer { client.close() }

            client.connection.on { stateChange in
                if stateChange.current == .connected {
                    let channel = client.channels.get("test")

                    channel.presence.enter("john.doe") { errorInfo in
                        channel.presence.get { members, error in
                            // members is the array of members present
                        }
                    }
                }
            }
        }

        it("testQueryingThePresenceHistory") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRealtime(options: options)
            defer { client.close() }

            let channel = client.channels.get("test")

            channel.presence.history { presencePage, error in
                let presencePage = presencePage!
                if let first = presencePage.items.first {
                    print(first.action) // Any of .enter, .update or .leave
                    print(first.clientId as Any) // client ID of member
                    print(first.data as Any) // optional data payload of member
                    presencePage.next { nextPage, error in
                        // retrieved the next page in nextPage
                    }
                }
            }
        }

        it("testMakeRestClientAndChannel") {
            let client = ARTRest(key: "xxxx:xxxx")
            let channel = client.channels.get("test")
            _ = channel
        }

        it("testRestPublishMessage") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRest(options: options)
            let channel = client.channels.get("test")

            channel.publish("myEvent", data: "Hello!")
        }

        it("testRestQueryingTheHistory") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRest(options: options)
            let channel = client.channels.get("test")

            channel.history { messagesPage, error in
                let messagesPage = messagesPage!
                print(messagesPage.items.first as Any)
                print(messagesPage.items.first?.data as Any) // payload for the message
                messagesPage.next { nextPage, error in
                    // retrieved the next page in nextPage
                }
                print(messagesPage.hasNext) // true, there are more pages
            }
        }

        it("testRestPresenceOnAChannel") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRest(options: options)
            let channel = client.channels.get("test")

            channel.presence.get { membersPage, error in
                let membersPage = membersPage!
                print(membersPage.items.first as Any)
                print((membersPage.items.first)?.data as Any) // payload for the message
                membersPage.next { nextPage, error in
                    // retrieved the next page in nextPage
                }
                print(membersPage.hasNext) // true, there are more pages
            }
        }

        it("testRestQueryingThePresenceHistory") {
            let options = AblyTests.clientOptions(requestToken: true)
            let client = ARTRest(options: options)
            let channel = client.channels.get("test")

            channel.presence.history { presencePage, error in
                let presencePage = presencePage!
                if let first = presencePage.items.first {
                    print(first.clientId as Any) // client ID of member
                    presencePage.next { nextPage, error in
                        // retrieved the next page in nextPage
                    }
                }
            }
        }

        it("testGenerateToken") {
            let client = ARTRest(options: AblyTests.commonAppSetup())

            client.auth.requestToken(nil, with: nil) { tokenDetails, error in
                let tokenDetails = tokenDetails!
                print(tokenDetails.token) // "xVLyHw.CLchevH3hF....MDh9ZC_Q"
                let client = ARTRest(token: tokenDetails.token)
                _ = client
            }
        }
        
        it("testFetchingStats") {
            let client = ARTRest(options: AblyTests.commonAppSetup())
            client.channels.get("test").publish("foo", data: "bar") { _ in
                client.stats { statsPage, error in
                    let statsPage = statsPage!
                    print(statsPage.items.first as Any)
                    statsPage.next { nextPage, error in
                        // retrieved the next page in nextPage
                    }
                }
            }
        }
        
        it("testFetchingTime") {
            let client = ARTRest(options: AblyTests.commonAppSetup())
            
            client.time { time, error in
                print(time as Any) // 2016-02-09 03:59:24 +0000
            }
        }

    }

}
