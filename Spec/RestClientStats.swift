//
//  RestClient.stats.swift
//  ably
//
//  Created by Yavor Georgiev on 11.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

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

private func queryStats(_ client: ARTRest, _ query: ARTStatsQuery) -> ARTPaginatedResult<AnyObject> {
    var stats: ARTPaginatedResult<AnyObject>?
    let dummyError = ARTErrorInfo()
    var error: ARTErrorInfo? = dummyError

    try! client.stats(query, callback: { result, err in
        stats = result as! ARTPaginatedResult<AnyObject>?
        error = err
    })

    while error === dummyError {
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, CFTimeInterval(0.1), Bool(0))
    }
    
    if let error = error {
        XCTFail(error.message)
    }
    
    return stats!
}

private func getPage(_ paginator: ((ARTPaginatedResult<AnyObject>?, ARTErrorInfo?) -> Void) -> Void) -> ARTPaginatedResult<AnyObject> {
    var newResult: ARTPaginatedResult<AnyObject>?
    let dummyError = ARTErrorInfo()
    var error: ARTErrorInfo? = dummyError
    paginator({ paginatorResult, err in
        newResult = paginatorResult
        error = err
    })
    
    while error === dummyError {
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, CFTimeInterval(0.1), Bool(0))
    }
    
    if let error = error {
        XCTFail(error.message)
    }
    
    return newResult!
}

class RestClientStats: QuickSpec {
    override func spec() {
        describe("RestClient") {
            // RSC6
            context("stats") {
                // RSC6a
                context("result") {
                    let calendar = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!
                    let dateComponents = NSDateComponents()
                    dateComponents.year = calendar.component(NSCalendar.Unit.year, from: NSDate() as Date) - 1
                    dateComponents.month = 2
                    dateComponents.day = 3
                    dateComponents.hour = 16
                    dateComponents.minute = 3
                    let date = calendar.date(from: dateComponents as DateComponents)!
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone!
                    dateFormatter.dateFormat = "YYYY-MM-dd:HH:mm"
                    
                    let statsFixtures: JSON = [
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
                    
                    var statsOptions = ARTClientOptions()

                    beforeEach {
                        statsOptions = postTestStats(statsFixtures)
                    }
                    
                    it("should match minute-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .forwards
                        
                        let result = queryStats(client, query)
                        expect(result.items.count).to(equal(3))
                        
                        let totalInbound = result.items.reduce(0 as UInt, {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.inbound.all.messages.count
                            }
                            return $0
                        })
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        
                        let totalOutbound = result.items.reduce(0 as UInt, {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.outbound.all.messages.count
                            }
                            return $0
                        })
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match hour-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.start = date
                        query.direction = .forwards
                        query.unit = .hour
                        
                        let result = queryStats(client, query)
                        let totalInbound = result.items.reduce(0 as UInt, {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.inbound.all.messages.count
                            }
                            return $0
                        })
                        let totalOutbound = result.items.reduce(0 as UInt, {
                            if let stats = $1 as? ARTStats {
                                return $0 + stats.outbound.all.messages.count
                            }
                            return $0
                        })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match day-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.date(byAdding: .day, value: 1, to: date, options: NSCalendar.Options(rawValue: 0))
                        query.direction = .forwards
                        query.unit = .month
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should match month-level inbound and outbound fixture data (forwards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = calendar.date(byAdding: .month, value: 1, to: date, options: NSCalendar.Options(rawValue: 0))
                        query.direction = .forwards
                        query.unit = .month
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50 + 60 + 70))
                        expect(totalOutbound).to(equal(20 + 10 + 40))
                    }
                    
                    it("should contain only one item when limit is 1 (backwards") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(60))
                        expect(totalOutbound).to(equal(10))
                    }
                    
                    it("should contain only one item when limit is 1 (forwards") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(60) // 20XX-02-03:16:04
                        query.limit = 1
                        query.direction = .forwards
                        
                        let result = queryStats(client, query)
                        let totalInbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.inbound.all.messages.count })
                        let totalOutbound = (result.items as! [ARTStats]).reduce(0, { $0 + $1.outbound.all.messages.count })
                        
                        expect(result.items.count).to(equal(1))
                        expect(totalInbound).to(equal(50))
                        expect(totalOutbound).to(equal(20))
                    }
                    
                    it("should be paginated according to the limit (backwards") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1

                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(7000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())
                        
                        let secondPage = getPage(firstPage.next as! ((ARTPaginatedResult<AnyObject>?, ARTErrorInfo?) -> Void) -> Void)
                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())
                        
                        let thirdPage = getPage(secondPage.next as! ((ARTPaginatedResult<AnyObject>?, ARTErrorInfo?) -> Void) -> Void)
                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(5000))
                        expect(thirdPage.isLast).to(beTrue())
                        
                        let firstPageAgain = getPage(thirdPage.first as! ((ARTPaginatedResult<AnyObject>?, ARTErrorInfo?) -> Void) -> Void)
                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(7000))
                    }
                    
                    it("should be paginated according to the limit (fowards)") {
                        let client = ARTRest(options: statsOptions)
                        let query = ARTStatsQuery()
                        query.end = date.addingTimeInterval(120) // 20XX-02-03:16:05
                        query.limit = 1
                        query.direction = .forwards
                        
                        let firstPage = queryStats(client, query)
                        expect(firstPage.items.count).to(equal(1))
                        expect((firstPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(5000))
                        expect(firstPage.hasNext).to(beTrue())
                        expect(firstPage.isLast).to(beFalse())
                        
                        let secondPage = getPage(firstPage.next as! ((ARTPaginatedResult<AnyObject>?, ARTErrorInfo?) -> Void) -> Void)
                        expect(secondPage.items.count).to(equal(1))
                        expect((secondPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(6000))
                        expect(secondPage.hasNext).to(beTrue())
                        expect(secondPage.isLast).to(beFalse())
                        
                        let thirdPage = getPage(secondPage.next as! ((ARTPaginatedResult<AnyObject>?, ARTErrorInfo?) -> Void) -> Void)
                        expect(thirdPage.items.count).to(equal(1))
                        expect((thirdPage.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(7000))
                        expect(thirdPage.isLast).to(beTrue())
                        
                        let firstPageAgain = getPage(thirdPage.first as! ((ARTPaginatedResult<AnyObject>?, ARTErrorInfo?) -> Void) -> Void)
                        expect(firstPageAgain.items.count).to(equal(1))
                        expect((firstPageAgain.items as! [ARTStats])[0].inbound.all.messages.data).to(equal(5000))
                    }
                }
                
                // RSC6b
                context("query") {
                    // RSC6b1
                    context("start") {
                        it("should return an error when later than end") {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.start = NSDate.distantFuture
                            query.end = NSDate.distantPast

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
                        }
                    }
                    
                    // RSC6b2
                    context("direction") {
                        it("should be backwards by default") {
                            let query = ARTStatsQuery()
                            
                            expect(query.direction).to(equal(ARTQueryDirection.backwards));
                        }
                    }
                    
                    // RSC6b3
                    context("limit") {
                        it("should have a default value of 100") {
                            let query = ARTStatsQuery()
                            
                            expect(query.limit).to(equal(100));
                        }
                        
                        it("should return an error when greater than 1000") {
                            let client = ARTRest(key: "fake:key")
                            let query = ARTStatsQuery()
                            
                            query.limit = 1001;

                            expect{try client.stats(query, callback:{ status, result in })}.to(throwError())
                        }
                    }
                    
                    // RSC6b4
                    context("unit") {
                        it("should default to minute") {
                            let query = ARTStatsQuery()
                            
                            expect(query.unit).to(equal(ARTStatsGranularity.minute))
                        }
                    }
                }
            }
        }
    }
}
