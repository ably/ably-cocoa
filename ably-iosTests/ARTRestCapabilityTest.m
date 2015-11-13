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
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRest.h"
#import "ARTChannel.h"
#import "ARTChannelCollection.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"

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

- (void)withRestRestrictCap:(void (^)(ARTRest *rest))cb {
    if (!_rest) {
        ARTClientOptions * theOptions = [ARTTestUtil clientOptions];
        [ARTTestUtil setupApp:theOptions withAlteration:TestAlterationRestrictCapability cb:^(ARTClientOptions *options) {
            if (options) {
                options.useTokenAuth = true;
                options.clientId = @"client_string";
                
                ARTRest *r = [[ARTRest alloc] initWithOptions:options];
                _rest = r;
                cb(_rest);
            }
        }];
        return;
    }
    else {
        cb(_rest);
    }
}

- (void)testPublishRestricted {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimpleDisconnected"];
    [self withRestRestrictCap:^(ARTRest * rest) {
        ARTChannel *channel = [rest.channels get:@"canpublish:test"];
        [channel publish:@"publish" callback:^(NSError *error) {
            XCTAssert(!error);
            ARTChannel *channel2 = [rest.channels get:@"cannotPublishToThisChannelName"];
            [channel2 publish:@"publish" callback:^(NSError *error) {
                XCTAssert(error);
                [expectation fulfill];
            }];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
