//
//  ARTRestPresenceTest.m
//  ably-ios
//
//  Created by vic on 13/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTRestChannel.h"
#import "ARTRestPresence.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTChannelCollection.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"

@interface ARTRestPresenceTest : XCTestCase {
    ARTRest *_rest;
}
@end

@implementation ARTRestPresenceTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

- (void)testPresence {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];

        [channel.presence get:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            NSArray *presence = [result items];

            XCTAssertEqual(6, [presence count]);
            ARTPresenceMessage *p0 = presence[0];
//            ARTPresenceMessage *p1 = presence[1];
//            ARTPresenceMessage *p2 = presence[2];
            ARTPresenceMessage *p3 = presence[3];
            ARTPresenceMessage *p4 = presence[4];
            ARTPresenceMessage *p5 = presence[5];
            
            
            XCTAssertEqualObjects(@"client_bool", p0.clientId);
            XCTAssertEqualObjects(@"true", [p0 content]);
            
            
            //TODO use ARTTestUtil cipher and check they match up.
            //XCTAssertEqualObjects(@"client_decoded", p1.clientId);
            //XCTAssertEqualObjects([p1 content], @"{\"example\":{\"json\":\"Object\"}}");
            
            //XCTAssertEqualObjects(@"client_encoded", p2.clientId);
            //XCTAssertEqualObjects([p2 content], @"HO4cYSP8LybPYBPZPHQOtuD53yrD3YV3NBoTEYBh4U0N1QXHbtkfsDfTspKeLQFt");
            
            XCTAssertEqualObjects(@"client_int", p3.clientId);
            XCTAssertEqualObjects(@"24", [p3 content]);
            
            XCTAssertEqualObjects(@"client_json", p4.clientId);
            XCTAssertEqualObjects(@"{ \"test\": \"This is a JSONObject clientData payload\"}", [p4 content]);
            
            XCTAssertEqualObjects(@"client_string", p5.clientId);
            XCTAssertEqualObjects(@"This is a string clientData payload", [p5 content]);
            
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];
        [channel.presence history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            NSArray *presence = [result items];
            XCTAssertEqual(6, [presence count]);
            [expectation fulfill];

        }];
    }];
     [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryDefaultBackwards {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];
        [channel.presence history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            NSArray *presence = [result items];
            XCTAssertEqual(6, [presence count]);
            ARTPresenceMessage * m = [presence objectAtIndex:[presence count] -1];
            XCTAssertEqualObjects(@"true", [m content]);
            [expectation fulfill];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryDirection {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];
        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.direction = ARTQueryDirectionForwards;
        [channel.presence history:query callback:^(ARTPaginatedResult *result, NSError *error) {
            XCTAssert(!error);
            NSArray *presence = [result items];
            XCTAssertEqual(6, [presence count]);
            ARTPresenceMessage * m = [presence objectAtIndex:0];
            XCTAssertEqualObjects(@"true", [m content]);
            [expectation fulfill];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPresenceLimit {
    XCTestExpectation *exp = [self expectationWithDescription:@"testLimit"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channelOne = [rest.channels get:@"name"];
        ARTDataQuery *query = [[ARTDataQuery alloc] init];
        query.limit = 1001;
        XCTAssertThrows([channelOne.presence history:query callback:^(ARTPaginatedResult *result, NSError *error){}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
