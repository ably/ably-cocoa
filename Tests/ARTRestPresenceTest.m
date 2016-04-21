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
#import "ARTChannels.h"
#import "ARTDataQuery.h"
#import "ARTPaginatedResult.h"
#import "ARTChannels+Private.h"

@interface ARTRestPresenceTest : XCTestCase

@end

@implementation ARTRestPresenceTest

- (void)tearDown {
    [super tearDown];
}

- (void)testPresence {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    ARTChannels_getChannelNamePrefix = nil; // Force that channel name is not changed.

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];

    [channel.presence get:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
        XCTAssert(!error);
        NSArray *presence = [result items];

        XCTAssertEqual(6, [presence count]);
        ARTPresenceMessage *p0 = presence[0];
        //ARTPresenceMessage *p1 = presence[1];
        //ARTPresenceMessage *p2 = presence[2];
        ARTPresenceMessage *p3 = presence[3];
        ARTPresenceMessage *p4 = presence[4];
        ARTPresenceMessage *p5 = presence[5];

        XCTAssertEqualObjects(@"client_bool", p0.clientId);
        XCTAssertEqualObjects(@"true", [p0 data]);

        //TODO use ARTTestUtil cipher and check they match up.
        //XCTAssertEqualObjects(@"client_decoded", p1.clientId);
        //XCTAssertEqualObjects([p1 data], @"{\"example\":{\"json\":\"Object\"}}");
        
        //XCTAssertEqualObjects(@"client_encoded", p2.clientId);
        //XCTAssertEqualObjects([p2 data], @"HO4cYSP8LybPYBPZPHQOtuD53yrD3YV3NBoTEYBh4U0N1QXHbtkfsDfTspKeLQFt");
        
        XCTAssertEqualObjects(@"client_int", p3.clientId);
        XCTAssertEqualObjects(@"24", [p3 data]);
        
        XCTAssertEqualObjects(@"client_json", p4.clientId);
        XCTAssertEqualObjects(@"{ \"test\": \"This is a JSONObject clientData payload\"}", [p4 data]);
        
        XCTAssertEqualObjects(@"client_string", p5.clientId);
        XCTAssertEqualObjects(@"This is a string clientData payload", [p5 data]);
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistory {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    ARTChannels_getChannelNamePrefix = nil; // Force that channel name is not changed.
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];
    [channel.presence history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
        XCTAssert(!error);
        NSArray *presence = [result items];
        XCTAssertEqual(6, [presence count]);
        [expectation fulfill];
    } error:nil];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryDefaultBackwards {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    ARTChannels_getChannelNamePrefix = nil; // Force that channel name is not changed.
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];
    [channel.presence history:[[ARTDataQuery alloc] init] callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
        XCTAssert(!error);
        NSArray *presence = [result items];
        XCTAssertEqual(6, [presence count]);
        ARTPresenceMessage *m = [presence objectAtIndex:[presence count] -1];
        XCTAssertEqualObjects(@"true", [m data]);
        [expectation fulfill];
    } error:nil];

    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testHistoryDirection {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    ARTChannels_getChannelNamePrefix = nil; // Force that channel name is not changed.
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channel = [rest.channels get:@"persisted:presence_fixtures"];
    ARTDataQuery *query = [[ARTDataQuery alloc] init];
    query.direction = ARTQueryDirectionForwards;
    [channel.presence history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error) {
        XCTAssert(!error);
        NSArray *presence = [result items];
        XCTAssertEqual(6, [presence count]);
        ARTPresenceMessage *m = [presence objectAtIndex:0];
        XCTAssertEqualObjects(@"true", [m data]);
        [expectation fulfill];
    } error:nil];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPresenceLimit {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channelOne = [rest.channels get:@"name"];
    ARTDataQuery *query = [[ARTDataQuery alloc] init];
    query.limit = 1001;
    NSError *error;
    BOOL valid = [channelOne.presence history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error){} error:&error];
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssert(error.code == ARTDataQueryErrorLimit);
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testPresenceLimitIgnoringError {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTRestChannel *channelOne = [rest.channels get:@"name"];
    ARTDataQuery *query = [[ARTDataQuery alloc] init];
    query.limit = 1001;
    // Forcing an invalid query where the error is ignored and the result should be invalid (the request was canceled)
    BOOL requested = [channelOne.presence history:query callback:^(ARTPaginatedResult *result, ARTErrorInfo *error){} error:nil];
    XCTAssertFalse(requested);
}

@end
