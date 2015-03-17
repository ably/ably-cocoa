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
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTTestUtil.h"
@interface ARTRestPresenceTest : XCTestCase {
    ARTRest *_rest;
    ARTOptions *_options;
    float _timeout;
}

- (void)withRest:(void(^)(ARTRest *))cb;


@end

@implementation ARTRestPresenceTest

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
        [ARTTestUtil setupApp:_options cb:^(ARTOptions *options) {
            if (options) {
                _rest = [[ARTRest alloc] initWithOptions:options];
            }
            cb(_rest);
        }];
        return;
    }
    cb(_rest);
}

- (void)testTypesText {
    XCTFail(@"TODO write test");
    
}

- (void)testTypesBinary {
    XCTFail(@"TODO write test");
}
- (void)testHistoryText {
    XCTFail(@"TODO write test");
}
- (void)testHistoryBinary {
    XCTFail(@"TODO write test");
}
- (void)testHistoryForwardText {
    XCTFail(@"TODO write test");
}
- (void)testHistoryBackwardText {
    XCTFail(@"TODO write test");
}
- (void)testHistoryForwardLimit {
    XCTFail(@"TODO write test");
}
- (void)testHistoryPaginationForward {
    XCTFail(@"TODO write test");
}
- (void)testHistoryPaginationBackward {
    XCTFail(@"TODO write test");
}


@end
