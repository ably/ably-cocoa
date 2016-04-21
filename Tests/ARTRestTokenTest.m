//
//  ARTRestTokenTest.m
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
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTDataEncoder.h"
#import "ARTRestChannel.h"
#import "ARTChannels.h"
#import "ARTTokenDetails.h"
#import "ARTAuth.h"
#import "ARTAuth+Private.h"

@interface ARTRestTokenTest : XCTestCase

@end

@implementation ARTRestTokenTest

- (void)tearDown {
    [super tearDown];
}

- (void)testTokenSimple {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.useTokenAuth = true;
    options.clientId = @"testToken";
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTAuth *auth = rest.auth;
    XCTAssertEqual(auth.method, ARTAuthMethodToken);
    ARTRestChannel *c = [rest.channels get:@"getChannel"];
    [c publish:nil data:@"something" callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithBadToken {
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.useTokenAuth = true;
    options.clientId = @"testToken";
    options.token = @"this_is_a_bad_token";
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTAuth *auth = rest.auth;
    XCTAssertEqual(auth.method, ARTAuthMethodToken);
    ARTChannel *c= [rest.channels get:@"getChannel"];
    [c publish:nil data:@"something" callback:^(ARTErrorInfo *error) {
        XCTAssert(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testAuthURLForcesToken {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.authUrl = [NSURL URLWithString:@"some_url"];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTAuth *auth = rest.auth;
    XCTAssertEqual(auth.method, ARTAuthMethodToken);
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void)testTTLDefaultOneHour {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.clientId = @"clientIdThatForcesToken";
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTAuth *auth = rest.auth;
    ARTChannel *c = [rest.channels get:@"getChannel"];
    [c publish:nil data:@"invokeTokenRequest" callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        NSTimeInterval secs = [auth.tokenDetails.expires timeIntervalSinceDate:auth.tokenDetails.issued];
        XCTAssertEqual(secs, 3600);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithBorrowedAuthCb {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.useTokenAuth = true;
    options.clientId = @"testToken";
    ARTRest *firstRest = [[ARTRest alloc] initWithOptions:options];
    ARTAuth *auth = firstRest.auth;
    //options.authCallback = [auth getTheAuthCb]; //?!
    ARTRest *secondRest = [[ARTRest alloc] initWithOptions:options];
    XCTAssertEqual(auth.method, ARTAuthMethodToken);
    ARTChannel *c = [secondRest.channels get:@"getChannel"];
    [c publish:nil data:@"something" callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
