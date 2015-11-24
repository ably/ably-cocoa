//
//  ARTRestChannelPublishTest.m
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
#import "ARTTestUtil.h"
#import "ARTPayload+Private.h"
#import "ARTLog.h"
#import "ARTRestChannel.h"
#import "ARTChannelCollection.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"

@interface ARTRestChannelPublishTest : XCTestCase {
    ARTRest *_rest;
}
@end

@implementation ARTRestChannelPublishTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    _rest = nil;
}

- (void)testTypesByText {

    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    NSString * message1 = @"message1";
    NSString * message2 = @"message2";
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testTypesByText"];
        [channel publish:message1 callback:^(NSError *error) {
            XCTAssert(!error);
            [channel publish:message2 callback:^(NSError *error) {
                XCTAssert(!error);
                ARTDataQuery *query = [[ARTDataQuery alloc] init];
                query.direction = ARTQueryDirectionForwards;
                [channel history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                    XCTAssert(!error);
                    NSArray *messages = [result items];
                    XCTAssertEqual(2, messages.count);
                    ARTMessage *m0 = messages[0];
                    ARTMessage *m1 = messages[1];
                    XCTAssertEqualObjects([m0 content], message1);
                    XCTAssertEqualObjects([m1 content], message2);
                    [expectation fulfill];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testPublishArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishArray"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTRestChannel *channel = [rest.channels get:@"channel"];
        NSString *test1 = @"test1";
        NSString *test2 = @"test2";
        NSString *test3 = @"test3";

        NSArray *messages = @[[[ARTMessage alloc] initWithData:test1 name:nil],
                              [[ARTMessage alloc] initWithData:test2 name:nil],
                              [[ARTMessage alloc] initWithData:test3 name:nil]];

        [channel publishMessages:messages callback:^(NSError *error) {
            XCTAssert(!error);
            [channel history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
                XCTAssert(!error);
                NSArray *messages = [result items];
                XCTAssertEqual(3, messages.count);
                ARTMessage *m0 = messages[0];
                ARTMessage *m1 = messages[1];
                ARTMessage *m2 = messages[2];
                XCTAssertEqualObjects([m0 content], test3);
                XCTAssertEqualObjects([m1 content], test2);
                XCTAssertEqualObjects([m2 content], test1);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


/**
 Currently the payloadArraySizeLimit is default to INT_MAX. Here we bring that number down to 2
 To show that publishing an array over the limit throws an exception.
 */
-(void) testPublishTooManyInArray {
    XCTestExpectation *exp = [self expectationWithDescription:@"testPublishTooManyInArray"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"channel"];
        NSArray *messages = @[[[ARTMessage alloc] initWithData:@"test1" name:nil],
                              [[ARTMessage alloc] initWithData:@"test2" name:nil],
                              [[ARTMessage alloc] initWithData:@"test3" name:nil]];
        [ARTPayload getPayloadArraySizeLimit:2 modify:true];
        XCTAssertThrows([channel publish:messages callback:^(NSError *error) {}]);
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublishUnJsonableType {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testPresence"];
    [ARTTestUtil testRest:^(ARTRest *rest) {
        _rest = rest;
        ARTChannel *channel = [rest.channels get:@"testTypesByText"];
        XCTAssertThrows([channel publish:channel callback:^(NSError *error){}]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
