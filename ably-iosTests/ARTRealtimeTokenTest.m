//
//  ARTRealtimeTokenTest.m
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTRealtime+Private.h"
#import "ARTLog.h"
@interface ARTRealtimeTokenTest : XCTestCase {
    ARTRealtime * _realtime;
}
@end

@implementation ARTRealtimeTokenTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    _realtime = nil;
}

/*
//TODO until socketrocket returns error codes we cannot implement this
-(void)testTokenExpiresGetsReissued {

    
    XCTFail(@"This won't work until SocketRocket returns ably error codes");
    XCTestExpectation *exp= [self expectationWithDescription:@"testTokenExpires"];
    [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTClientOptions *options) {
        options.authOptions.clientId = @"clientIdThatForcesToken";
        const int fiveSecondsMilli = 5000;
        options.authOptions.ttl = fiveSecondsMilli;
        ARTRealtime * realtime =[[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        ARTAuth * auth = realtime.auth;
        ARTAuthOptions * authOptions = [auth getAuthOptions];
        XCTAssertEqual(authOptions.tokenDetails.expires - authOptions.tokenDetails.issued,  fiveSecondsMilli);
        ARTRealtimeChannel * c= [realtime channel:@"getChannel"];
        NSString * oldToken = authOptions.tokenDetails.token;
        [c publish:@"something" cb:^(ARTStatus *status) {
            XCTAssertEqual(ARTStatusOk, status.status);
            sleep(6); // wait for token to expire
            [c publish:@"somethingElse" cb:^(ARTStatus *status) {
                NSString * newToken = authOptions.tokenDetails.token;
                XCTAssertFalse([newToken isEqualToString:oldToken]);
                XCTAssertEqual(ARTStatusOk, status.status);
                [exp fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
*/
@end
