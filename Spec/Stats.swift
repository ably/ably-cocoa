import Ably
import Nimble
import Quick
import SwiftyJSON
import Foundation

class Stats: QuickSpec {
    override func spec() {
        describe("Stats") {
            let encoder = ARTJsonLikeEncoder()

            // TS6
            func reusableTestsTestAttribute(_ attribute: String) {
                let data: JSON = [
                    [ attribute: [ "messages": [ "count": 5], "all": [ "data": 10 ] ] ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
                let subject = stats?.value(forKey: attribute) as? ARTStatsMessageTypes

                it("should return a MessagesTypes object") {
                    expect(subject).to(beAnInstanceOf(ARTStatsMessageTypes.self))
                }

                // TS5
                it("should return value for message counts") {
                    expect(subject?.messages.count).to(equal(5))
                }

                // TS5
                it("should return value for all data transferred") {
                    expect(subject?.all.data).to(equal(10))
                }

                // TS2
                it("should return zero for empty values") {
                    expect(subject?.presence.count).to(equal(0))
                }
            }
            
            context("all") {
                reusableTestsTestAttribute("all")
            }
            
            context("persisted") {
                reusableTestsTestAttribute("persisted")
            }

            // TS7
            for direction in ["inbound", "outbound"] {
                context(direction) {
                    let data: JSON = [
                        [ direction: [
                            "realtime": [ "messages": [ "count": 5] ],
                            "all": [ "messages": [ "count": 25 ], "presence": [ "data": 210 ] ]
                        ] ]
                    ]
                    let rawData = try! data.rawData()
                    let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
                    let subject = stats?.value(forKey: direction) as? ARTStatsMessageTraffic

                    it("should return a MessageTraffic object") {
                        expect(subject).to(beAnInstanceOf(ARTStatsMessageTraffic.self))
                    }

                    // TS5
                    it("should return value for realtime message counts") {
                        expect(subject?.realtime.messages.count).to(equal(5))
                    }

                    // TS5
                    it("should return value for all presence data") {
                        expect(subject?.all.presence.data).to(equal(210))
                    }
                }
            }

            // TS4
            context("connections") {
                let data: JSON = [
                    [ "connections": [ "tls": [ "opened": 5], "all": [ "peak": 10 ] ] ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
                let subject = stats?.connections

                it("should return a ConnectionTypes object") {
                    expect(subject).to(beAnInstanceOf(ARTStatsConnectionTypes.self))
                }

                it("should return value for tls opened counts") {
                    expect(subject?.tls.opened).to(equal(5))
                }

                it("should return value for all peak connections") {
                    expect(subject?.all.peak).to(equal(10))
                }

                // TS2
                it("should return zero for empty values") {
                    expect(subject?.all.refused).to(equal(0))
                }
            }

            // TS9
            context("channels") {
                let data: JSON = [
                    [ "channels": [ "opened": 5, "peak": 10 ] ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
                let subject = stats?.channels

                it("should return a ResourceCount object") {
                    expect(subject).to(beAnInstanceOf(ARTStatsResourceCount.self))
                }

                it("should return value for opened counts") {
                    expect(subject?.opened).to(equal(5))
                }

                it("should return value for peak channels") {
                    expect(subject?.peak).to(equal(10))
                }

                // TS2
                it("should return zero for empty values") {
                    expect(subject?.refused).to(equal(0))
                }
            }

            // TS8
            for requestType in ["apiRequests", "tokenRequests"] {
                let data: JSON = [
                    [ requestType: [ "succeeded": 5, "failed": 10 ] ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
                let subject = stats?.value(forKey: requestType) as? ARTStatsRequestCount

                context(requestType) {
                    it("should return a RequestCount object") {
                        expect(subject).to(beAnInstanceOf(ARTStatsRequestCount.self))
                    }

                    it("should return value for succeeded") {
                        expect(subject?.succeeded).to(equal(5))
                    }

                    it("should return value for failed") {
                        expect(subject?.failed).to(equal(10))
                    }
                }
            }

            context("interval") {
                let data: JSON = [
                    [ "intervalId": "2004-02-01:05:06" ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats

                it("should return a Date object representing the start of the interval") {
                    let dateComponents = NSDateComponents()
                    dateComponents.year = 2004
                    dateComponents.month = 2
                    dateComponents.day = 1
                    dateComponents.hour = 5
                    dateComponents.minute = 6
                    dateComponents.timeZone = NSTimeZone(name: "UTC") as TimeZone?

                    let expected = NSCalendar(identifier: NSCalendar.Identifier.gregorian)?.date(from: dateComponents as DateComponents)

                    expect(stats?.intervalTime()).to(equal(expected))
                }
            }
            
            context("push") {
                let data: JSON = [
                    [ "push":
                        [
                            "messages": 10,
                            "notifications": [
                                "invalid": 1,
                                "attempted": 2,
                                "successful": 3,
                                "failed": 4
                            ],
                            "directPublishes": 5
                        ]
                    ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats
                let subject = stats?.pushes

                it("should return a ARTStatsPushCount object") {
                    expect(subject).to(beAnInstanceOf(ARTStatsPushCount.self))
                }

                it("should return value for messages count") {
                    expect(subject?.messages).to(equal(10))
                }

                it("should return value for invalid notifications") {
                    expect(subject?.invalid).to(equal(1))
                }

                it("should return value for attempted notifications") {
                    expect(subject?.attempted).to(equal(2))
                }

                it("should return value for successful notifications") {
                    expect(subject?.succeeded).to(equal(3))
                }

                it("should return value for failed notifications") {
                    expect(subject?.failed).to(equal(4))
                }

                it("should return value for directPublishes") {
                    expect(subject?.direct).to(equal(5))
                }
            }

            context("inProgress") {
                let data: JSON = [
                    [ "inProgress": "2004-02-01:05:06" ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats

                it("should return a Date object representing the last sub-interval included in this statistic") {
                    let dateComponents = NSDateComponents()
                    dateComponents.year = 2004
                    dateComponents.month = 2
                    dateComponents.day = 1
                    dateComponents.hour = 5
                    dateComponents.minute = 6
                    dateComponents.timeZone = NSTimeZone(name: "UTC") as TimeZone?

                    let expected = NSCalendar(identifier: NSCalendar.Identifier.gregorian)?.date(from: dateComponents as DateComponents)

                    expect(stats?.dateFromInProgress()).to(equal(expected))
                }
            }
            
            context("count") {
                let data: JSON = [
                    [ "count": 55 ]
                ]
                let rawData = try! data.rawData()
                let stats = try! encoder.decodeStats(rawData)[0] as? ARTStats

                it("should return value for number of lower-level stats") {
                    expect(stats?.count).to(equal(55))
                }
            }
        }
    }
}
