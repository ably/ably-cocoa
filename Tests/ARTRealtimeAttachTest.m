//
//  ARTRealtimeTest.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTRealtime+TestSuite.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtimePresence.h"
#import "ARTRealtimeChannel.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTEventEmitter.h"
#import "ARTStatus.h"
#import "ARTAuth.h"
#import "ARTTokenParams.h"
#import "ARTTokenDetails.h"

@interface ARTRealtimeAttachTest : XCTestCase
@end

@implementation ARTRealtimeAttachTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAttachOnce {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];

            __block bool hasAttached = false;
            [channel on:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttaching) {
                    XCTAssertNil(stateChange.reason);
                    [channel attach];
                }
                if (stateChange.current == ARTRealtimeChannelAttached) {
                    XCTAssertNil(stateChange.reason);
                    [channel attach];
                    
                    if(!hasAttached) {
                        hasAttached = true;
                        [channel detach];
                    }
                    else {
                        XCTFail(@"duplicate call to attach shouldnt happen");
                    }
                }
                if (stateChange.current == ARTRealtimeChannelDetached) {
                    [expectation fulfill];
                }
            }];
            [channel attach];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testAttachMultipleChannels {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-1", __FUNCTION__]];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-2", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel1 = [realtime.channels get:@"test_attach_multiple1"];
    [channel1 attach];
    ARTRealtimeChannel *channel2 = [realtime.channels get:@"test_attach_multiple2"];
    [channel2 attach];
    [channel1 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [expectation1 fulfill];
        }
    }];
    [channel2 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [expectation2 fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testDetach {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"detach"];
            [channel on:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttached) {
                    [channel detach];
                }
                else if (stateChange.current == ARTRealtimeChannelDetached) {
                    [expectation fulfill];
                }
            }];
            [channel attach];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testDetaching {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block BOOL detachingHit = NO;
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"detach"];
            [channel on:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttached) {
                    [channel detach];
                }
                else if (stateChange.current == ARTRealtimeChannelDetaching) {
                    detachingHit = YES;
                }
                else if (stateChange.current == ARTRealtimeChannelDetached) {
                    if(detachingHit) {
                        [expectation fulfill];
                    }
                    else {
                        XCTFail(@"Detaching state not emitted prior to detached");
                    }
                }
            }];
            [channel attach];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

-(void)testDetachingIgnoresDetach {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        
        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"testDetachingIgnoresDetach"];
            [channel on:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttached) {
                    [channel detach];
                }
                if (stateChange.current == ARTRealtimeChannelDetaching) {
                    [channel detach];
                }
                if (stateChange.current == ARTRealtimeChannelDetached) {
                    [expectation fulfill];
                }
            }];
            [channel attach];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testAttachFailsOnFailedConnection {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];
            __block bool hasFailed = false;
            [channel on:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttached) {
                    if(!hasFailed) {
                        XCTAssertNil(stateChange.reason);
                        [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                    }
                }
                else if (stateChange.current == ARTRealtimeChannelFailed) {
                    XCTAssertNotNil(stateChange.reason);
                    [channel attach:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNotNil(errorInfo);
                        [expectation fulfill];
                    }];
                }
            }];
            [channel attach];
            [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
                ARTRealtimeConnectionState state = stateChange.current;
                if(state == ARTRealtimeFailed) {
                    hasFailed = true;
                    [channel attach];
                }
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testAttachRestricted {
    __weak XCTestExpectation *startup = [self expectationWithDescription:[NSString stringWithFormat:@"%s-ClientOptions", __FUNCTION__]];
    __block ARTClientOptions *options;
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withAlteration:TestAlterationRestrictCapability callback:^(ARTClientOptions *_options) {
        options = _options;
        [startup fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"some_unpermitted_channel"];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current != ARTRealtimeChannelAttaching) {
            XCTAssertEqual(channel.state, ARTRealtimeChannelFailed);
            [expectation fulfill];
            [channel off];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testAttachingChannelFails {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel1 = [realtime.channels get:@"channel"];
    [channel1 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttaching) {
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
        }
        else {
            XCTAssertEqual(ARTRealtimeChannelFailed, channel1.state);
            [expectation fulfill];
        }
    }];
    [channel1 attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testAttachedChannelFails {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel1 = [realtime.channels get:@"channel"];
    [channel1 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
        }
        else if (stateChange.current != ARTRealtimeChannelAttaching) {
            XCTAssertEqual(ARTRealtimeChannelFailed, channel1.state);
            [expectation fulfill];
        }
    }];
    [channel1 attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testChannelClosesOnClose {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel1 = [realtime.channels get:@"channel"];
    [channel1 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [realtime close];
        }
        else if (stateChange.current != ARTRealtimeChannelAttaching) {
            XCTAssertEqual(ARTRealtimeChannelDetached, channel1.state);
            [expectation fulfill];
        }
    }];
    [channel1 attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testPresenceEnterRestricted {
    __weak XCTestExpectation *startup = [self expectationWithDescription:[NSString stringWithFormat:@"%s-ClientOptions", __FUNCTION__]];
    __block ARTClientOptions *options;
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withAlteration:TestAlterationRestrictCapability callback:^(ARTClientOptions *_options) {
        options = _options;
        [startup fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    // Connection
    options.clientId = @"some_client_id";
    options.autoConnect = false;

    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];

    // FIXME: there is setupApp, testRealtime, testRest, ... try to unify them and then use this code
    ARTTokenParams *tokenParams = [[ARTTokenParams alloc] initWithClientId:options.clientId];
    tokenParams.capability = @"{\"canpublish:*\":[\"publish\"],\"canpublish:andpresence\":[\"presence\",\"publish\"],\"cansubscribe:*\":[\"subscribe\"]}";

    [realtime.auth authorize:tokenParams options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
        options.token = tokenDetails.token;
    }];

    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        ARTErrorInfo *errorInfo = stateChange.reason;
        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"some_unpermitted_channel"];
            [channel.presence enter:@"not_allowed_here" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNotNil(errorInfo);
                [expectation fulfill];
            }];
        }
        else if (state == ARTRealtimeFailed) {
            if (errorInfo) {
                XCTFail(@"%@", errorInfo);
            }
            else {
                XCTFail();
            }
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

@end
