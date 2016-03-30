//
//  RestClientPresence.swift
//  Ably
//
//  Created by Ricardo Pereira on 18/03/16.
//  Copyright © 2016 Ably. All rights reserved.
//

import Quick
import Nimble

class RestClientPresence: QuickSpec {
    override func spec() {
        describe("Presence") {

            // RSP3
            context("get") {

                // RSP3a
                it("should return a PaginatedResult page containing the first page of members") {
                    let options = AblyTests.commonAppSetup()
                    let client = ARTRest(options: options)
                    let channel = client.channels.get("test")

                    var disposable = [ARTRealtime]()
                    defer {
                        for clientItem in disposable {
                            clientItem.close()
                        }
                    }

                    let expectedData = "online"
                    let expectedPattern = "^user(\\d+)$"
                    waitUntil(timeout: testTimeout) { done in
                        // Load 150 members (2 pages)
                        disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 150, data:expectedData, options: options) {
                            done()
                        }
                    }

                    waitUntil(timeout: testTimeout) { done in
                        channel.presence.get { membersPage, error in
                            expect(error).to(beNil())

                            let membersPage = membersPage!
                            expect(membersPage).to(beAnInstanceOf(ARTPaginatedResult))
                            expect(membersPage.items).to(haveCount(100))

                            let members = membersPage.items as! [ARTPresenceMessage]
                            expect(members).to(allPass({ member in
                                return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                    && (member!.data as? NSObject) == expectedData
                            }))

                            expect(membersPage.hasNext).to(beTrue())
                            expect(membersPage.isLast).to(beFalse())

                            membersPage.next { nextPage, error in
                                expect(error).to(beNil())
                                let nextPage = nextPage!
                                expect(nextPage).to(beAnInstanceOf(ARTPaginatedResult))
                                expect(nextPage.items).to(haveCount(50))

                                let members = nextPage.items as! [ARTPresenceMessage]
                                expect(members).to(allPass({ member in
                                    return NSRegularExpression.match(member!.clientId, pattern: expectedPattern)
                                        && (member!.data as? NSObject) == expectedData
                                }))

                                expect(nextPage.hasNext).to(beFalse())
                                expect(nextPage.isLast).to(beTrue())
                                done()
                            }
                        }
                    }
                }

            }

            // RSP4
            context("history") {

                // RSP4b
                context("query argument") {

                    // RSP4b1
                    it("start and end should filter members between those two times") {
                        let options = AblyTests.commonAppSetup()
                        let client = ARTRest(options: options)
                        let channel = client.channels.get("test")

                        var disposable = [ARTRealtime]()
                        defer {
                            for clientItem in disposable {
                                clientItem.close()
                            }
                        }

                        let query = ARTDataQuery()

                        waitUntil(timeout: testTimeout) { done in
                            disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 25, data:nil, options: options) {
                                done()
                            }
                        }

                        query.start = NSDate()

                        waitUntil(timeout: testTimeout) { done in
                            disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 3, data:nil, options: options) {
                                done()
                            }
                        }

                        query.end = NSDate()

                        waitUntil(timeout: testTimeout) { done in
                            disposable += AblyTests.addMembersSequentiallyToChannel("test", members: 10, data:nil, options: options) {
                                done()
                            }
                        }

                        waitUntil(timeout: testTimeout) { done in
                            try! channel.presence.history(query) { membersPage, error in
                                expect(error).to(beNil())
                                expect(membersPage!.items).to(haveCount(3))
                                done()
                            }
                        }
                    }

                    // RSP4b1
                    it("start must be equal to or less than end and is unaffected by the request direction") {
                        let client = ARTRest(options: AblyTests.commonAppSetup())
                        let channel = client.channels.get("test")

                        let query = ARTDataQuery()
                        query.direction = .Backwards
                        query.end = NSDate()
                        query.start = query.end!.dateByAddingTimeInterval(10.0)

                        expect { try channel.presence.history(query) { _, _ in } }.to(throwError { (error: ErrorType) in
                            expect(error._code).to(equal(ARTDataQueryError.TimestampRange.rawValue))
                        })

                        query.direction = .Forwards

                        expect { try channel.presence.history(query) { _, _ in } }.to(throwError { (error: ErrorType) in
                            expect(error._code).to(equal(ARTDataQueryError.TimestampRange.rawValue))
                        })
                    }

                }

            }

        }
    }
}

