//
//  ARTRestCapabilityTest.m
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
@interface ARTRestCapabilityTest : XCTestCase {
    ARTRest *_rest;
}

@end

@implementation ARTRestCapabilityTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}


- (void)withRest:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        ARTOptions * theOptions = [ARTTestUtil jsonRestOptions];
        [ARTTestUtil setupApp:theOptions cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}

- (void)withRestRestricCap:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        ARTOptions * theOptions = [ARTTestUtil jsonRestOptions];
        [ARTTestUtil setupApp:theOptions withAlteration:TestAlterationRestrictCapability cb:^(ARTOptions *options) {
            if (options) {
                options.authOptions.useTokenAuth = true;
                options.authOptions.clientId = @"something";
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}


- (void)testAuthBlanket {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimpleDisconnected"];
    [self withRestRestricCap:^(ARTRest * rest) {
        ARTRestChannel * channel = [rest channel:@"canpublish:test"];
        [channel publish:@"publish" cb:^(ARTStatus status) {
            XCTAssertEqual(status, ARTStatusOk);
            ARTRestChannel * channel2 = [rest channel:@"cannotPublishToThisChannelName"];
            [channel2 publish:@"publish" cb:^(ARTStatus status) {
                XCTAssertEqual(status, ARTStatusError);
                [expectation fulfill];
                
            }];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
- (void)testAuthEqual {
    XCTFail(@"TODO write test");
}
- (void)testAuthEmptyOps {
    XCTFail(@"TODO write test");
}
- (void)testAuthEmptyPaths {
    XCTFail(@"TODO write test");
}
- (void)testAuthNonEmptyOps {
    XCTFail(@"TODO write test");
}
- (void)testAuthNonEmptyPaths {
    XCTFail(@"TODO write test");
}
- (void)testAuthWildcardOps {
    XCTFail(@"TODO write test");
}
- (void)testAuthCapability7 {
    XCTFail(@"TODO write test");
}
- (void)testAuthWildcardResources {
    XCTFail(@"TODO write test");
}
- (void)testAuthCapability9 {

    XCTFail(@"TODO write test");
}
- (void)testAuthCapability10 {

    XCTFail(@"TODO write test");
}
- (void)testInvalidCapabilities1 { //java: authinvalid0
    XCTFail(@"TODO write test");
}
- (void)testInvalidCapabilities2 {
    XCTFail(@"TODO write test");
}
- (void)testInvalidCapabilities3 {
    XCTFail(@"TODO write test");
}

*/

@end
