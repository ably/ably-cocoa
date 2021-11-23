import Ably
import Nimble
import Quick
import SwiftyJSON
import Foundation

private func postTestStats(_ stats: JSON) -> ARTClientOptions {
    let options = AblyTests.setupOptions(AblyTests.jsonRestOptions, forceNewApp: true);
    
    let keyBase64 = encodeBase64(options.key ?? "")

    let request = NSMutableURLRequest(url: URL(string: "\(AblyTests.clientOptions().restUrl().absoluteString)/stats")!)
    
    request.httpMethod = "POST"
    request.httpBody = try? stats.rawData()
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Basic \(keyBase64)", forHTTPHeaderField: "Authorization")
    
    let (_, responseError, httpResponse) = NSURLSessionServerTrustSync().get(request)

    if let error = responseError {
        XCTFail(error.localizedDescription)
    } else if let response = httpResponse {
        if response.statusCode != 201 {
            XCTFail("Posting stats fixtures failed: code response \(response.statusCode)")
        }
    }
    
    return options
}

private func queryStats(_ client: ARTRest, _ query: ARTStatsQuery, file: FileString = #file, line: UInt = #line) -> ARTPaginatedResult<ARTStats> {
    let (stats, error) = (AblyTests.waitFor(timeout: testTimeout, file: file, line: line) { value in
        expect {
            try client.stats(query, callback: { result, err in
                value((result, err))
            })
        }.toNot(throwError() { _ in value(nil) })
    })!
    if let error = error {
        fail(error.message, file: file, line: line)
    }
    return stats!
}
                    private let calendar = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!
                    private let dateComponents: NSDateComponents = {
                        let dateComponents = NSDateComponents()
                        dateComponents.year = calendar.component(NSCalendar.Unit.year, from: NSDate() as Date) - 1
                        dateComponents.month = 2
                        dateComponents.day = 3
                        dateComponents.hour = 16
                        dateComponents.minute = 3
                        return dateComponents
                    }()
                    private let date = calendar.date(from: dateComponents as DateComponents)!
                    private let dateFormatter: DateFormatter = {
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                        dateFormatter.dateFormat = "YYYY-MM-dd:HH:mm"
                        return dateFormatter
                    }()
                    
                    private let statsFixtures: JSON = [
                        [
                            "intervalId": dateFormatter.string(from: date), // 20XX-02-03:16:03
                            "inbound": [ "realtime": [ "messages": [ "count": 50, "data": 5000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 20, "data": 2000 ] ] ]
                        ],
                        [
                            "intervalId": dateFormatter.string(from: date.addingTimeInterval(60)), // 20XX-02-03:16:04
                            "inbound": [ "realtime": [ "messages": [ "count": 60, "data": 6000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 10, "data": 1000 ] ] ]
                        ],
                        [
                            "intervalId": dateFormatter.string(from: date.addingTimeInterval(120)), // 20XX-02-03:16:05
                            "inbound": [ "realtime": [ "messages": [ "count": 70, "data": 7000 ] ] ],
                            "outbound": [ "realtime": [ "messages": [ "count": 40, "data": 4000 ] ] ],
                            "persisted": [ "presence": [ "count": 20, "data": 2000 ] ],
                            "connections": [ "tls": [ "peak": 20,  "opened": 10 ] ],
                            "channels": [ "peak": 50, "opened": 30 ],
                            "apiRequests": [ "succeeded": 50, "failed": 10 ],
                            "tokenRequests": [ "succeeded": 60, "failed": 20 ]
                        ]
                    ]
                    
                    private var statsOptions = ARTClientOptions()

class RestClientStats: XCTestCase {

override class var defaultTestSuite : XCTestSuite {
    let _ = calendar
    let _ = dateComponents
    let _ = date
    let _ = dateFormatter
    let _ = statsFixtures
    let _ = statsOptions

    return super.defaultTestSuite
}

        
            // RSC6
            
                // RSC6a
                

                    func beforeEach__RestClient__stats__result() {
print("START HOOK: RestClientStats.beforeEach__RestClient__stats__result")

                        statsOptions = postTestStats(statsFixtures)
print("END HOOK: RestClientStats.beforeEach__RestClient__stats__result")

                    }
                    
                    func skipped__test__001__RestClient__stats__result__should_match_minute_level_inbound_and_outbound_fixture_data__forwards_() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .forwards
                        
                        let result = queryStats(client, query)
                        expect(result.items.count).to(equal(3))
                        
                        let totalInbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.inbound.all.messages.count
                        })
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        
                        let totalOutbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.outbound.all.messages.count
                        })
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    func test__002__RestClient__stats__result__should_match_hour_level_inbound_and_outbound_fixture_data__forwards_() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .forwards
                        query.unit = .hour
                        
                        let result = queryStats(client, query)
                        let totalInbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.inbound.all.messages.count
                        })
                        let totalOutbound = result.items.reduce(0 as UInt, {
                            return $0 + $1.outbound.all.messages.count
                        })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    func test__003__RestClient__stats__result__should_match_day_level_inbound_and_outbound_fixture_data__forwards_() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.date(byAdding: .day, value: 1, to: date, options: NSCalendar.Options(rawValue: 0))
                        query.direction = .forwards
                        query.unit = .month
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    func skipped__test__004__RestClient__stats__result__should_match_month_level_inbound_and_outbound_fixture_data__forwards_() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.date(byAdding: .month, value: 1, to: date, options: NSCalendar.Options(rawValue: 0))
                        query.direction = .forwards
                        query.unit = .month
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    func skipped__test__005__RestClient__stats__result__should_contain_only_one_item_when_limit_is_1__backwards() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(60))
                        expect(totalOutbound).to(equal(10))
                    }
                    
                    func test__006__RestClient__stats__result__should_contain_only_one_item_when_limit_is_1__forwards() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1
                        query.direction = .forwards
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50))
                        expect(totalOutbound).to(equal(20))
                    }
                    
                    func test__007__RestClient__stats__result__should_be_paginated_according_to_the_limit__backwards() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1

                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items)[0].inbound.all.messages.data).to(equal(7000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())
                        
                        guard let secondPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            firstPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items)[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())
                        
                        guard let thirdPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            secondPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items)[0].inbound.all.messages.data).to(equal(5000))
                        expect(thirdPage.isLast).to(beTrue())
                        
                        guard let firstPageAgain: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            thirdPage.first { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items)[0].inbound.all.messages.data).to(equal(7000))
                    }
                    
                    func skipped__test__008__RestClient__stats__result__should_be_paginated_according_to_the_limit__fowards_() {
beforeEach__RestClient__stats__result()

                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1
                        query.direction = .forwards
                        
                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items)[0].inbound.all.messages.data).to(equal(5000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())
                        
                        guard let secondPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            firstPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items)[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())
                        
                        guard let thirdPage: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            secondPage.next { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items)[0].inbound.all.messages.data).to(equal(7000))
                        expect(thirdPage.isLast).to(beTrue())
                        
                        guard let firstPageAgain: ARTPaginatedResult<ARTStats> = (AblyTests.waitFor(timeout: testTimeout) { value in
                            thirdPage.first { page, err in
                                expect(err).to(beNil())
                                value(page)
                            }
                        }) else {
                            return
                        }

                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items)[0].inbound.all.messages.data).to(equal(5000))
                    }
                
                // RSC6b
                
                    // RSC6b1
                    
                        func test__009__RestClient__stats__query__start__should_return_an_error_when_later_than_end() {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.start = NSDate.distantFuture
                            query.end = NSDate.distantPast

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
                        }
                    
                    // RSC6b2
                    
                        func test__010__RestClient__stats__query__direction__should_be_backwards_by_default() {
                            let query = ARTStatsQuery()
                            
                            expect(query.direction).to(equal(ARTQueryDirection.backwards));
                        }
                    
                    // RSC6b3
                    
                        func test__011__RestClient__stats__query__limit__should_have_a_default_value_of_100() {
                            let query = ARTStatsQuery()
                            
                            expect(query.limit).to(equal(100));
                        }
                        
                        func test__012__RestClient__stats__query__limit__should_return_an_error_when_greater_than_1000() {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.limit = 1001;

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
                        }
                    
                    // RSC6b4
                    
                        func test__013__RestClient__stats__query__unit__should_default_to_minute() {
                            let query = ARTStatsQuery()
                            
                            expect(query.unit).to(equal(ARTStatsGranularity.minute))
                        }
}
