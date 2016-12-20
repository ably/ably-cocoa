//
//  ARTRealtimeChannelTest.m
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

#import "ARTRealtime.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtimeChannel+Private.h"
#import "ARTRealtimePresence.h"
#import "ARTEventEmitter.h"
#import "ARTTestUtil.h"
#import "ARTCrypto+Private.h"
#import "ARTChannelOptions.h"
#import "ARTChannels+Private.h"

@interface ARTRealtimeChannelTest : XCTestCase

@end

@implementation ARTRealtimeChannelTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAttach {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];
            [channel on:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttached) {
                    [expectation fulfill];
                }
            }];
            [channel attach];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachBeforeConnect {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"attach_before_connect"];
    [channel attach];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachDetach {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"attach_detach"];
    [channel attach];
    
    __block BOOL attached = NO;
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attached = YES;
            [channel detach];
        }
        if (attached && stateChange.current == ARTRealtimeChannelDetached) {
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachDetachAttach {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"attach_detach_attach"];
    [channel attach];
    __block BOOL attached = false;
    __block int attachCount = 0;
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            attachCount++;
            attached = true;
            if (attachCount == 1) {
                [channel detach];
            }
            else if (attachCount == 2) {
                [expectation fulfill];
            }
        }
        if (attached && stateChange.current == ARTRealtimeChannelDetached) {
            [channel attach];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSubscribeUnsubscribe {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSString *lostMessage = @"lost";
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"test"];
    ARTEventListener __block *subscription = [channel subscribe:^(ARTMessage *message) {
        if([[message data] isEqualToString:@"testString"]) {
            [channel unsubscribe:subscription];
            [channel publish:nil data:lostMessage callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }
        else if([[message data] isEqualToString:lostMessage]) {
            XCTFail(@"unsubscribe failed");
        }
    }];

    [channel publish:nil data:@"testString" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        NSString *finalMessage = @"final";
        [channel subscribe:^(ARTMessage *message) {
            if([[message data] isEqualToString:finalMessage]) {
                [expectation fulfill];
            }
        }];
        [channel publish:nil data:finalMessage callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testFailingFailsChannel {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
    [channel on:^(ARTChannelStateChange *stateChange) {
        if (stateChange.current == ARTRealtimeChannelAttached) {
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
        }
        else if (stateChange.current == ARTRealtimeChannelFailed) {
            [channel publish:nil data:@"will_fail" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNotNil(errorInfo);
                [expectation fulfill];
            }];
        }
    }];
    [channel attach];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testGetChannels {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *c1 = [realtime.channels get:@"channel"];
    ARTRealtimeChannel *c2 = [realtime.channels get:@"channel2"];
    ARTRealtimeChannel *c3 = [realtime.channels get:@"channel3"];

    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    for (ARTRealtimeChannel *channel in realtime.channels) {
        [d setValue:channel forKey:channel.name];
    }
    XCTAssertEqual([[d allKeys] count], 3);
    NSString *prefix = ARTChannels_getChannelNamePrefix();
    __block NSString *expectedName = [NSString stringWithFormat:@"%@-channel", prefix];
    XCTAssertEqualObjects([d valueForKey:expectedName], c1);
    expectedName = [NSString stringWithFormat:@"%@-channel2", prefix];
    XCTAssertEqualObjects([d valueForKey:expectedName], c2);
    expectedName = [NSString stringWithFormat:@"%@-channel3", prefix];
    XCTAssertEqualObjects([d valueForKey:expectedName], c3);

    [realtime.channels release:c3.name callback:^(ARTErrorInfo *errorInfo) {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        for (ARTRealtimeChannel *channel in realtime.channels) {
            [d setValue:channel forKey:channel.name];
        }
        XCTAssertEqual([[d allKeys] count], 2);
        expectedName = [NSString stringWithFormat:@"%@-channel", prefix];
        XCTAssertEqualObjects([d valueForKey:expectedName], c1);
        expectedName = [NSString stringWithFormat:@"%@-channel2", prefix];
        XCTAssertEqualObjects([d valueForKey:expectedName], c2);
    }];
    
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testGetSameChannelWithParams {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSString *channelName = @"channel";
    NSString *firstMessage = @"firstMessage";
    NSString *secondMessage = @"secondMessage";
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *c1 = [realtime.channels get:channelName];
    NSData *ivSpec = [[NSData alloc] initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0];
    NSData *keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
    ARTCipherParams *params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" key:keySpec iv:ivSpec];
    ARTRealtimeChannel *c2 = [realtime.channels get:channelName options:[[ARTChannelOptions alloc] initWithCipher:params]];
    [c1 publish:nil data:firstMessage callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [c2 publish:nil data:secondMessage callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
        }];
    }];
    __block int messageCount = 0;
    [c1 subscribe:^(ARTMessage *message) {
        if(messageCount == 0) {
            XCTAssertEqualObjects([message data], firstMessage);
        }
        else if (messageCount == 1) {
            XCTAssertEqualObjects([message data], secondMessage);
            [expectation fulfill];
        }
        messageCount++;
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachFails {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [channel on:^(ARTChannelStateChange *stateChange) {
                if (stateChange.current == ARTRealtimeChannelAttached) {
                    [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                }
            }];
            [channel attach];
        }
        else if(state == ARTRealtimeFailed) {
            [channel attach:^(ARTErrorInfo *errorInfo) {
                XCTAssert(errorInfo);
                XCTAssertEqual(errorInfo.code, 90000);
                [expectation fulfill];
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testClientIdPreserved {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];

    __weak XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-1", __FUNCTION__]];
    __weak XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%s-2", __FUNCTION__]];

    NSString *firstClientId = @"firstClientId";
    NSString *channelName = @"channelName";

    // First instance
    options.clientId = firstClientId;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    ARTRealtimeChannel *channel = [realtime.channels get:channelName];

    // Second instance
    options.clientId = @"secondClientId";
    ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
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

    [channel2.presence subscribe:^(ARTPresenceMessage *message) {
        XCTAssertEqualObjects(message.clientId, firstClientId);
        [channel2 off];
        [expectation1 fulfill];
    }];

    [ARTTestUtil waitForWithTimeout:&attached list:@[channel, channel2] timeout:1.5];

    // Enters "firstClientId"
    [channel.presence enter:@"First Client" callback:^(ARTErrorInfo *errorInfo) {
        XCTAssertNil(errorInfo);
        [expectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
