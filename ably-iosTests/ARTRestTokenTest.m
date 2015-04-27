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
#import "ARTTestUtil.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
@interface ARTRestTokenTest : XCTestCase {
    ARTRest *_rest;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end


@implementation ARTRestTokenTest

- (void)setUp {
    [ARTLog setLogLevel:ArtLogLevelVerbose];
    [super setUp];
}

- (void)tearDown {
    [ARTLog setLogLevel:ArtLogLevelWarn];
    _rest = nil;
    [super tearDown];
}

- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}

- (void)testTokenSimple{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRestTimeBadHost"];

    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
        options.authOptions.useTokenAuth = true;
        options.authOptions.clientId = @"testToken";
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        
        ARTAuth * auth = rest.auth;
        ARTAuthMethod authMethod = [auth getAuthMethod];
        XCTAssertEqual(authMethod, ARTAuthMethodToken);
        ARTRestChannel * c= [rest channel:@"getChannel"];
        [c publish:@"something" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            [expectation fulfill];
           
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
 //TODO implement
 
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
*/


@end
