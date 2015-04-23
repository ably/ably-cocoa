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
@interface ARTRestTokenTest : XCTestCase {
    ARTRest *_rest;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end


@implementation ARTRestTokenTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
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


//consider test that auth method token is used in correct cases.

- (void)testTokenSimple{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"testRestTimeBadHost"];

 
    [ARTTestUtil setupApp:[ARTTestUtil jsonRestOptions] cb:^(ARTOptions *options) {
     //   options.authOptions.keyValue = nil;
     //   options.authOptions.clientId = nil;
        
        options.authOptions.useTokenAuth = true;
        options.authOptions.clientId = @"testToken";
        ARTRest * rest = [[ARTRest alloc] initWithOptions:options];
        
        ARTAuth * auth = rest.auth;
        ARTAuthMethod authMethod = [auth getAuthMethod];
        XCTAssertEqual(authMethod, ARTAuthMethodToken);
      ARTRestChannel * c= [rest channel:@"getChannel"];
        [c publish:@"something" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            NSLog(@"publish worked");
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
