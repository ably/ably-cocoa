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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTAppSetup.h"
@interface ARTRestTokenTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
    float _timeout;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end

@implementation ARTRestTokenTest

- (void)setUp {
    [super setUp];
    _options = [[ARTOptions alloc] init];
    _options.restHost = @"sandbox-rest.ably.io";
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        [ARTAppSetup setupApp:_options cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}

- (void)testNullParams {
    XCTFail(@"TODO write test");
}
- (void)testEmptyParams {
    XCTFail(@"TODO write test");
}
- (void)testExplicitTimestamp {
    XCTFail(@"TODO write test");
}
- (void)testExplicitInvalidTimestamp {
    XCTFail(@"TODO write test");
}

- (void)testSystemTimestamp {
    XCTFail(@"TODO write test");
}
- (void)testDuplicateNonce {
    XCTFail(@"TODO write test");
}

- (void)testClientId { //authclientid0
    XCTFail(@"TODO write test");
}
- (void)testSubsetKeyCapabilityGen {
    XCTFail(@"TODO write test");
}

- (void)testSpecifiedKeyGen {
    XCTFail(@"TODO write test");
}
- (void)testInvalidMac {
    XCTFail(@"TODO write test");
}
- (void)testSpecifiedTTL {
    XCTFail(@"TODO write test");
}
- (void)testExcessiveTTL {
    XCTFail(@"TODO write test");
}
- (void)testInvalidTTL {
    XCTFail(@"TODO write test");
}



@end
