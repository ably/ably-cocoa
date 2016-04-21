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
#import "ARTLog.h"
#import "ARTRestChannel.h"
#import "ARTChannels.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"

@interface ARTRestChannelPublishTest : XCTestCase

@end

@implementation ARTRestChannelPublishTest

- (void)tearDown {
    [super tearDown];
}

- (void)testTypesByText {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *message1 = @"message1";
    NSString *message2 = @"message2";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channel = [rest.channels get:@"testTypesByText"];
    [channel publish:nil data:message1 callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [channel publish:nil data:message2 callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            ARTDataQuery *query = [[ARTDataQuery alloc] init];
            query.direction = ARTQueryDirectionForwards;
            [channel history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
                XCTAssert(!error);
                NSArray *messages = [result items];
                XCTAssertEqual(2, messages.count);
                ARTMessage *m0 = messages[0];
                ARTMessage *m1 = messages[1];
                XCTAssertEqualObjects([m0 data], message1);
                XCTAssertEqualObjects([m1 data], message2);
                [expectation fulfill];
            } error:nil];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublishArray {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channel = [rest.channels get:@"channel"];
    NSString *test1 = @"test1";
    NSString *test2 = @"test2";
    NSString *test3 = @"test3";

    NSArray *messages = @[[[ARTMessage alloc] initWithName:nil data:test1],
                          [[ARTMessage alloc] initWithName:nil data:test2],
                          [[ARTMessage alloc] initWithName:nil data:test3]];

    [channel publish:messages callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [channel history:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            XCTAssert(!error);
            NSArray *messages = [result items];
            XCTAssertEqual(3, messages.count);
            ARTMessage *m0 = messages[0];
            ARTMessage *m1 = messages[1];
            ARTMessage *m2 = messages[2];
            XCTAssertEqualObjects([m0 data], test3);
            XCTAssertEqualObjects([m1 data], test2);
            XCTAssertEqualObjects([m2 data], test1);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPublishUnJsonableType {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTChannel *channel = [rest.channels get:@"testTypesByText"];
    XCTAssertThrows([channel publish:nil data:channel callback:^(ARTErrorInfo *error){}]);
}

@end
