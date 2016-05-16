//
//  ARTRestTimeTest.m
//  ably-ios
//
//  Created by vic on 13/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions+Private.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTAuth.h"
#import "ARTAuth+Private.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions.h"
#import "ARTChannel.h"
#import "ARTChannels.h"

@interface ARTRestInitTest : XCTestCase

@end

@implementation ARTRestInitTest

- (void)tearDown {
    [super tearDown];
}

- (void)testInternetIsUp {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    [rest internetIsUp:^(BOOL isUp) {
        XCTAssertTrue(isUp);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithKey {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    @try {
        [ARTClientOptions setDefaultEnvironment:@"sandbox"];
        ARTRest *rest = [[ARTRest alloc] initWithKey:options.key];
        ARTChannel *c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }
    @finally {
        [ARTClientOptions setDefaultEnvironment:nil];
    }
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithNoKey {
    NSString *key = @"";
    XCTAssertThrows([[ARTRest alloc] initWithKey:key]);
}

- (void)testInitWithKeyBad {
    __weak XCTestExpectation *exp = [self expectationWithDescription:@"testInitWithKeyBad"];
    @try {
        [ARTClientOptions setDefaultEnvironment:@"sandbox"];
        ARTRest *rest = [[ARTRest alloc] initWithKey:@"badkey:secret"];
        ARTChannel *c = [rest.channels get:@"test"];
        XCTAssert(c);
        [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
            XCTAssert(error);
            XCTAssertEqual(40005, error.code); //invalid credential
            [exp fulfill];
        }];
    }
    @finally {
        [ARTClientOptions setDefaultEnvironment:nil];
    }
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithOptions {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTChannel *c = [rest.channels get:@"test"];
    XCTAssert(c);
    [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithOptionsEnvironment {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTClientOptions *envOptions = [[ARTClientOptions alloc] init];
    envOptions.key = options.key;
    envOptions.environment = @"sandbox";
    ARTRest *rest = [[ARTRest alloc] initWithOptions:envOptions];
    ARTChannel *c = [rest.channels get:@"test"];
    [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testGetAuth {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
    ARTChannel *c = [rest.channels get:@"test"];
    XCTAssert(c);
    [c publish:nil data:@"message" callback:^(ARTErrorInfo *error) {
        XCTAssert(!error);
        ARTAuth *auth = rest.auth;
        XCTAssert(auth);
        ARTAuthOptions *authOptions = auth.options;
        XCTAssertEqual(authOptions.key, options.key);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testInitWithOptionsBad {
    XCTAssertThrows([[ARTClientOptions alloc] initWithKey:@"bad"]);
    XCTAssertThrows([[ARTRest alloc] initWithOptions:[[ARTClientOptions alloc] init]]);
}

- (void)testDefaultAuthType {
    ARTRest* rest = [[ARTRest alloc] initWithKey:@"key:secret"];
    XCTAssertEqual([rest.auth method], ARTAuthMethodBasic);
}

@end
