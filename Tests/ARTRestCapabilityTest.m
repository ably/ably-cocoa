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
#import "ARTRestChannel.h"
#import "ARTChannels.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTAuth.h"
#import "ARTTokenParams.h"
#import "ARTTokenDetails.h"
#import "ARTChannels+Private.h"

@interface ARTRestCapabilityTest : XCTestCase {
    ARTRest *_rest;
}

@end

@implementation ARTRestCapabilityTest

- (void)tearDown {
    _rest = nil;
    [super tearDown];
}

- (void)testPublishRestricted {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    ARTChannels_getChannelNamePrefix = nil; // Force that channel name is not changed.

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.clientId = @"client_string";

    ARTTokenParams *tokenParams = [[ARTTokenParams alloc] initWithClientId:options.clientId];
    tokenParams.capability = @"{\"canpublish:*\":[\"publish\"],\"canpublish:andpresence\":[\"presence\",\"publish\"],\"cansubscribe:*\":[\"subscribe\"]}";

    [[[ARTRest alloc] initWithOptions:options].auth authorize:tokenParams options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
        options.token = tokenDetails.token;
        ARTRest *rest = [[ARTRest alloc] initWithOptions:options];
        ARTRestChannel *channel = [rest.channels get:@"canpublish:test"];
        [channel publish:nil data:@"publish" callback:^(ARTErrorInfo *error) {
            XCTAssert(!error);
            ARTRestChannel *channel2 = [rest.channels get:@"cannotPublishToThisChannelName"];
            [channel2 publish:nil data:@"publish" callback:^(ARTErrorInfo *error) {
                XCTAssert(error);
                [expectation fulfill];
            }];
            
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
