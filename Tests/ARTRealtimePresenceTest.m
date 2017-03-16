//
//  ARTRealtimePresenceTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTRealtime+TestSuite.h"
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTPaginatedResult.h"
#import "ARTEventEmitter.h"
#import "ARTTestUtil.h"
#import "ARTRest.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimePresence.h"
#import "ARTPresenceMap.h"
#import "ARTLog.h"
#import "ARTCrypto.h"

@interface ARTRealtimePresenceTest : XCTestCase

@end

@implementation ARTRealtimePresenceTest

- (void)tearDown {
    [super tearDown];
}

- (NSString *)getClientId {
    return @"theClientId";
}

- (NSString *)getSecondClientId {
    return @"secondClientId";
}

- (void)testTwoConnections {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];

    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-1", __FUNCTION__]];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-2", __FUNCTION__]];
    __weak XCTestExpectation *expectation3 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-3", __FUNCTION__]];
    NSString *channelName = @"testSingleEcho";
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];

    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];

    __block NSUInteger attached = 0;
    // Channel 1
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attached++;
        }
    }];
    // Channel 2
    [channel2 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attached++;
        }
    }];

    [channel subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects([message data], @"testStringEcho");
        [expectation1 fulfill];
    }];

    [channel2 subscribe:^(ARTMessage *message) {
        XCTAssertEqualObjects([message data], @"testStringEcho");
        [expectation2 fulfill];
    }];

    [ARTTestUtil waitForWithTimeout:&attached list:@[channel, channel2] timeout:1.5];

    [channel2 publish:nil data:@"testStringEcho" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [expectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
    [realtime2 testSuite_waitForConnectionToClose:self];
}

- (void)testEnterSimple {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];

    NSString *channelName = @"presTest";
    NSString *presenceEnter = @"client_has_entered";

    __weak XCTestExpectation *expectConnected = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [expectConnected fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    ARTRealtimeChannel *channel2 = [realtime.channels get:channelName];
    [channel2 attach];
    [channel attach];
    
    __weak XCTestExpectation *expectChannel2Connected = [self expectationWithDescription:@"presence message"];
    [channel2 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [expectChannel2Connected fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    __weak XCTestExpectation *expectPresenceMessage = [self expectationWithDescription:@"presence message"];
    [channel2.presence subscribe:^(ARTPresenceMessage *message) {
        [expectPresenceMessage fulfill];

    }];
    [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterAttachesTheChannel {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
    XCTAssertEqual(channel.state, ARTRealtimeChannelInitialized);
    [channel.presence enter:@"entered" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        XCTAssertEqual(channel.state, ARTRealtimeChannelAttached);
        [expectation fulfill];
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testSubscribeConnects {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"presBeforeAttachTest";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
    }];
    
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testUpdateConnects {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"presBeforeAttachTest";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [channel.presence update:@"update"  callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterBeforeConnect {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"testEnterBeforeConnect";
    NSString *presenceEnter = @"client_has_entered";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        XCTAssertEqualObjects([message data], presenceEnter);
        [expectation fulfill];
    }];
    
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterLeaveSimple {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    NSString *presenceLeave = @"byebye";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    void(^partialExpectationFulfill)(void) = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:2];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter) {
            XCTAssertEqualObjects([message data], presenceEnter);
            [channel.presence leave:presenceLeave callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                // Should wait for the publishing acknowledgement
                partialExpectationFulfill();
            }];
        }
        if(message.action == ARTPresenceLeave) {
            XCTAssertEqualObjects([message data], presenceLeave);
            partialExpectationFulfill();
        }
    }];
    
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterEnter {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    NSString *secondEnter = @"secondEnter";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    void(^partialExpectationFulfill)(void) = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:2];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter) {
            XCTAssertEqualObjects([message data], presenceEnter);
            [channel.presence enter:secondEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                // Should wait for the publishing acknowledgement
                partialExpectationFulfill();
            }];
        }
        else if(message.action == ARTPresenceUpdate) {
            XCTAssertEqualObjects([message data], secondEnter);
            partialExpectationFulfill();
        }
    }];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterUpdateSimple {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    NSString *update = @"updateMessage";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    void(^partialExpectationFulfill)(void) = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:2];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter) {
            XCTAssertEqualObjects([message data], presenceEnter);
            [channel.presence update:update callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                // Should wait for the publishing acknowledgement
                partialExpectationFulfill();
            }];
        }
        else if(message.action == ARTPresenceUpdate) {
            XCTAssertEqualObjects([message data], update);
            partialExpectationFulfill();
        }
    }];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testUpdateNull {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    void(^partialExpectationFulfill)(void) = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:2];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter) {
            XCTAssertEqualObjects([message data], presenceEnter);
            [channel.presence update:nil callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                // Should wait for the publishing acknowledgement
                partialExpectationFulfill();
            }];
        }
        else if(message.action == ARTPresenceUpdate) {
            XCTAssertEqualObjects([message data], nil);
            partialExpectationFulfill();
        }
    }];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterLeaveWithoutData {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];

    NSString *channelName = @"testEnterLeaveSimple";
    NSString *presenceEnter = @"client_has_entered";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    void(^partialExpectationFulfill)(void) = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:2];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if (message.action == ARTPresenceEnter) {
            XCTAssertEqualObjects([message data], presenceEnter);
            [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                // Should wait for the publishing acknowledgement
                partialExpectationFulfill();
            }];
        }
        if (message.action == ARTPresenceLeave) {
            XCTAssertEqualObjects([message data], presenceEnter);
            partialExpectationFulfill();
        }
        
    }];
    
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testUpdateNoEnter {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];

    NSString *update = @"update_message";

    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testUpdateNoEnter"];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter) {
            XCTAssertEqualObjects([message data], update);
            [expectation fulfill];
        }
    }];
    
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel attach];
        }
    }];
    
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence update:update callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
        
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterAndGet {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *enterData = @"online";
    NSString *channelName = @"test";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.clientId = [self getClientId];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [options setClientId:[self getSecondClientId]];
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
    [channel.presence enter:enterData callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [channel2.presence enter:enterData callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel2.presence get:^(NSArray<ARTPresenceMessage *> *members, ARTErrorInfo *error) {
                XCTAssert(!error);
                XCTAssertEqual(members[0].action, ARTPresencePresent);
                XCTAssertEqualObjects(members[0].clientId, [self getClientId]);
                XCTAssertEqualObjects([members[0] data], enterData);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
    [realtime2 testSuite_waitForConnectionToClose:self];
}

- (void)testEnterNoClientId {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
    [channel.presence enter:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo){
        XCTAssertNotNil(errorInfo);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterOnDetached {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel detach];
        }
        else if(channel.state == ARTRealtimeChannelDetached) {
            [channel.presence enter:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNotNil(errorInfo);
                [expectation fulfill];
            }];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterOnFailed {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel setFailed:[ARTStatus state:ARTStateError]];
        }
        else if (stateChange.current == ARTRealtimeChannelFailed) {
            [channel.presence enter:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNotNil(errorInfo);
                [expectation fulfill];
            }];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testLeaveAndGet {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *enterData = @"enter";
    NSString *leaveData = @"bye";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterAndGet"];
    [channel.presence subscribe:^(ARTPresenceMessage * message) {
        if (message.action == ARTPresenceEnter)  {
            XCTAssertEqualObjects([message data], enterData);
            [channel.presence leave:leaveData callback:^(ARTErrorInfo *error) {
                XCTAssert(!error);
                [channel.presence get:^(NSArray *members, ARTErrorInfo *error) {
                    XCTAssert(!error);
                    XCTAssertEqual(0, members.count);
                    [expectation fulfill];
                }];
            }];
        }
    }];

    [channel.presence enter:enterData callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testLeaveNoData {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *enter = @"enter";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterLeaveNoData"];
    void(^partialExpectationFulfill)(void) = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:2];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter) {
            XCTAssertEqualObjects([message data], enter);
            [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                // Should wait for the publishing acknowledgement
                partialExpectationFulfill();
            }];
        }
        else if(message.action == ARTPresenceLeave) {
            XCTAssertEqualObjects([message data], enter);
            partialExpectationFulfill();
        }
    }];
    [channel attach];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel.presence update:enter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testLeaveNoMessage {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *enter = @"enter";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterAndGet"];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter)  {
            XCTAssertEqualObjects([message data], enter);
            [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertEqualObjects([message data], enter);
            }];
        }
        if(message.action == ARTPresenceLeave) {
            XCTAssertEqualObjects([message data], enter);
            [expectation fulfill];
        }
    }];
    [channel.presence enter:enter callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testLeaveWithMessage {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *enter = @"enter";
    NSString *leave = @"bye";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterAndGet"];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        if(message.action == ARTPresenceEnter)  {
            XCTAssertEqualObjects([message data], enter);
            [channel.presence leave:leave callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertEqualObjects([message data], enter);
            }];
        }
        if(message.action == ARTPresenceLeave) {
            XCTAssertEqualObjects([message data], leave);
            [expectation fulfill];
        }
    }];
    [channel.presence enter:enter callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testLeaveOnDetached {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel detach];
        }
        else if (stateChange.current == ARTRealtimeChannelDetached) {
            XCTAssertThrows([channel.presence leave:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {}]);
            [expectation fulfill];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testLeaveOnFailed {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"testEnterNoClientId"];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [channel setFailed:[ARTStatus state:ARTStateError]];
        }
        else if (stateChange.current == ARTRealtimeChannelFailed) {
            XCTAssertThrows([channel.presence leave:@"thisWillFail" callback:^(ARTErrorInfo *errorInfo) {}]);
            [expectation fulfill];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterFailsOnError {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"presBeforeAttachTest";
    NSString *presenceEnter = @"client_has_entered";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if(state == ARTRealtimeConnected) {
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNotNil(errorInfo);
                [expectation fulfill];
            }];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testGetFailsOnDetachedOrFailed {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
    __block bool hasDisconnected = false;
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if(state == ARTRealtimeConnected) {
            [realtime onDisconnected];
        }
        else if(state == ARTRealtimeDisconnected) {
            hasDisconnected = true;
            XCTAssertThrows([channel.presence get:^(NSArray *result, ARTErrorInfo *error) {}]);
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
        }
        else if(state == ARTRealtimeFailed) {
            XCTAssertTrue(hasDisconnected);
            XCTAssertThrows([channel.presence get:^(NSArray *result, ARTErrorInfo *error) {}]);
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterClient {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *clientId = @"otherClientId";
    NSString *clientId2 = @"yetAnotherClientId";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    void(^partialFulfill)() = [ARTTestUtil splitFulfillFrom:self expectation:expectation in:4];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channelName"];
    [channel.presence enterClient:clientId data:nil callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        partialFulfill();
    }];
    [channel.presence enterClient:clientId2 data:nil callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        partialFulfill();
    }];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        partialFulfill();
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    __weak XCTestExpectation *expectationPresenceGet = [self expectationWithDescription:[NSString stringWithFormat:@"%s-PresenceGet", __FUNCTION__]];
    [channel.presence get:^(NSArray *members, ARTErrorInfo *error) {
        XCTAssert(!error);
        XCTAssertEqual(2, members.count);
        ARTPresenceMessage *m0 = [members objectAtIndex:0];
        // cannot guarantee the order
        if (![m0.clientId isEqualToString:clientId2] && ![m0.clientId isEqualToString:clientId]) {
            XCTFail(@"clientId1 is different from what's expected");
        }
        ARTPresenceMessage *m1 = [members objectAtIndex:1];
        if (![m1.clientId isEqualToString:clientId] && ![m1.clientId isEqualToString:clientId]) {
            XCTFail(@"clientId2 is different from what's expected");
        }
        [expectationPresenceGet fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testEnterClientIdFailsOnError {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channelName"];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if(state == ARTRealtimeConnected) {
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            [channel.presence  enterClient:@"clientId" data:@"" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNotNil(errorInfo);
                [expectation fulfill];
            }];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testWithNoClientIdUpdateLeaveEnterAnotherClient {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *otherClientId = @"otherClientId";
    NSString *data = @"data";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.clientId = nil;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channelName"];
    [channel.presence  enterClient:otherClientId data:@"" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [channel.presence updateClient:otherClientId data:data callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel.presence leaveClient:otherClientId data:@"" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }];
    }];
    __block int messageCount = 0;
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        XCTAssertEqualObjects(otherClientId, message.clientId);
        if(messageCount == 0) {
            XCTAssertEqual(message.action, ARTPresenceEnter);
            XCTAssertEqualObjects(message.data, @"");
        }
        else if(messageCount == 1) {
            XCTAssertEqual(message.action, ARTPresenceUpdate);
            XCTAssertEqualObjects(message.data, data);
        }
        else if(messageCount == 2) {
            XCTAssertEqual(message.action, ARTPresenceLeave);
            XCTAssertEqualObjects(message.data, data);
            [expectation fulfill];
        }
        messageCount++;
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testPresenceMap {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *channelName = @"channelName";
    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-1", __FUNCTION__]];
    options.clientId = [self getClientId];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [channel.presence enter:@"hi" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [expectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-2", __FUNCTION__]];
    [options setClientId: [self getSecondClientId]];
    XCTAssertEqual(options.clientId, [self getSecondClientId]);
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
    ARTRealtimePresenceQuery *query = [[ARTRealtimePresenceQuery alloc] init];
    query.waitForSync = false;
    [channel2.presence get:query callback:^(NSArray *members, ARTErrorInfo *error) {
        XCTAssert(!error);
        XCTAssertFalse(channel2.presence.syncComplete);
        [ARTTestUtil delay:1.0 block:^{
            XCTAssertTrue(channel2.presence.syncComplete);
            ARTPresenceMap *map = channel2.presenceMap;
            ARTPresenceMessage *m = [map.members objectForKey:[self getClientId]];
            XCTAssertFalse(m == nil);
            XCTAssertEqual(m.action, ARTPresencePresent);
            XCTAssertEqualObjects([m data], @"hi");
            [expectation2 fulfill];
        }];
    }];
    [channel2 attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testLeaveBeforeEnterThrows {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *channelName = @"channelName";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.clientId = [self getClientId];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    XCTAssertThrows([channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {}]); // leave before enter
    [channel.presence enter:nil callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) { //leave after enter
            XCTAssertNil(errorInfo);
            XCTAssertThrows([channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {}]); // leave after leave
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testSubscribeToAction {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    options.clientId = [self getClientId];
    NSString *channelName = @"presBeforeAttachTest";
    NSString *enter1 = @"enter1";
    NSString *update1 = @"update1";
    NSString *leave1 = @"leave1";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
        
    __block bool gotUpdate = false;
    __block bool gotEnter = false;
    __block bool gotLeave = false;
    ARTEventListener *leaveSub = [channel.presence subscribe:ARTPresenceLeave callback:^(ARTPresenceMessage *message) {
        XCTAssertEqualObjects([message data], leave1);
        gotLeave = true;
    }];
    ARTEventListener *updateSub=[channel.presence subscribe:ARTPresenceUpdate callback:^(ARTPresenceMessage *message) {
        XCTAssertEqualObjects([message data], update1);
        gotUpdate = true;
    }];
    ARTEventListener *enterSub =[channel.presence subscribe:ARTPresenceEnter callback:^(ARTPresenceMessage *message) {
        XCTAssertEqualObjects([message data], enter1);
        gotEnter = true;
    }];
    [channel.presence enter:enter1 callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [channel.presence update:update1 callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [channel.presence unsubscribe:updateSub];
            [channel.presence unsubscribe:enterSub];
            [channel.presence update:@"noone will get this" callback:^(ARTErrorInfo *errorInfo) {
                [channel.presence leave:leave1 callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [channel.presence enter:@"nor this" callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        XCTAssertTrue(gotUpdate);
                        XCTAssertTrue(gotEnter);
                        XCTAssertTrue(gotLeave);
                        [channel.presence unsubscribe:leaveSub];
                        [expectation fulfill];
                    }];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testPresenceWithData {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *channelName = @"channelName";
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.clientId = [self getClientId];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];
    [channel.presence enter:@"someDataPayload" callback:^(ARTErrorInfo *errorInfo) {
         XCTAssertNil(errorInfo);
    }];
    [channel.presence subscribe:^(ARTPresenceMessage *message) {
        [channel.presence get:^(NSArray<ARTPresenceMessage *> *members, ARTErrorInfo *error) {
            XCTAssert(!error);
            XCTAssertEqual(1, members.count);
            XCTAssertEqual(members[0].action, ARTPresencePresent);
            XCTAssertEqualObjects(members[0].clientId, [self getClientId]);
            XCTAssertEqualObjects([members[0] data], @"someDataPayload");
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

- (void)testPresenceWithDataOnLeave {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    NSString *channelName = @"channelName";
    NSData *dataPayload = [@"someDataPayload"  dataUsingEncoding:NSUTF8StringEncoding];
    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-1", __FUNCTION__]];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-2", __FUNCTION__]];
    options.clientId = [self getClientId];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];

    options.clientId = @"clientId2";
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];

    [channel2.presence subscribe:^(ARTPresenceMessage *message) {
        if (message.action == ARTPresenceLeave) {
            XCTAssertEqualObjects([message data], dataPayload);
            [expectation1 fulfill];
        }
    }];

    __block NSUInteger attached = 0;
    // Channel 1
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attached++;
        }
    }];

    // Channel 2
    [channel2 on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attached++;
        }
    }];

    [channel2 attach];
    [channel attach];

    [ARTTestUtil waitForWithTimeout:&attached list:@[channel, channel2] timeout:1.5];

    // Presence
    [channel.presence enter:dataPayload callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [channel.presence leave:@"" callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [expectation2 fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    [realtime testSuite_waitForConnectionToClose:self];
}

@end
