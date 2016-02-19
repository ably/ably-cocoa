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
#import "ARTCrypto.h"
#import "ARTChannelOptions.h"

@interface ARTRealtimeChannelTest : XCTestCase {
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
}
@end

@implementation ARTRealtimeChannelTest


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    if (_realtime) {
        [ARTTestUtil removeAllChannels:_realtime];
        [_realtime resetEventEmitter];
        [_realtime close];
    }
    _realtime = nil;
    if (_realtime2) {
        [ARTTestUtil removeAllChannels:_realtime2];
        [_realtime2 resetEventEmitter];
        [_realtime2 close];
    }
    _realtime2 = nil;
    [super tearDown];
}

- (void)testAttach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];
                [channel on:^(ARTErrorInfo *errorInfo) {
                    if (channel.state == ARTRealtimeChannelAttached) {
                        [expectation fulfill];
                    }
                }];
                [channel attach];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testAttachBeforeConnect     {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_before_connect"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"attach_before_connect"];
        [channel attach];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
                [expectation fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testAttachDetach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_detach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"attach_detach"];
        [channel attach];
        
        __block BOOL attached = NO;
        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
                attached = YES;
                [channel detach];
            }
            if (attached && channel.state == ARTRealtimeChannelDetached) {
                [expectation fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testAttachDetachAttach {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"attach_detach_attach"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"attach_detach_attach"];
        [channel attach];
        __block BOOL attached = false;
        __block int attachCount = 0;
        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
                attachCount++;
                attached = true;
                if (attachCount == 1) {
                    [channel detach];
                }
                else if (attachCount == 2) {
                    [expectation fulfill];
                }
            }
            if (attached && channel.state == ARTRealtimeChannelDetached) {
                [channel attach];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testSubscribeUnsubscribe {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"publish"];
    NSString * lostMessage = @"lost";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"test"];
        ARTEventListener __block *subscription = [channel subscribe:^(ARTMessage *message) {
            if([[message data] isEqualToString:@"testString"]) {
                [channel unsubscribe:subscription];
                [channel publish:nil data:lostMessage cb:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                }];
            }
            else if([[message data] isEqualToString:lostMessage]) {
                XCTFail(@"unsubscribe failed");
            }
        }];

        [channel publish:nil data:@"testString" cb:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            NSString * finalMessage = @"final";
            [channel subscribe:^(ARTMessage * message) {
                if([[message data] isEqualToString:finalMessage]) {
                    [expectation fulfill];
                }
            }];
            [channel publish:nil data:finalMessage cb:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}
 


- (void) testSuspendingDetachesChannel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSuspendingDetachesChannel"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
        __block bool gotCb=false;
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [realtime onSuspended];
            }
            else if(channel.state == ARTRealtimeChannelDetached) {
                if(!gotCb) {
                    [channel publish:nil data:@"will_fail" cb:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNotNil(errorInfo);
                        XCTAssertEqual(90001, errorInfo.code);
                        gotCb = true;
                        [realtime close];
                        [expectation fulfill];
                    }];
                }
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testFailingFailsChannel {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSuspendingDetachesChannel"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"channel"];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
            }
            else if(channel.state == ARTRealtimeChannelFailed) {
                [channel publish:nil data:@"will_fail" cb:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNotNil(errorInfo);
                    [expectation fulfill];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testGetChannels {
    XCTestExpectation *exp = [self expectationWithDescription:@"testGetChannels"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *c1 = [realtime.channels get:@"channel"];
        ARTRealtimeChannel *c2 = [realtime.channels get:@"channel2"];
        ARTRealtimeChannel *c3 = [realtime.channels get:@"channel3"];
        {
            NSMutableDictionary * d = [[NSMutableDictionary alloc] init];
            for (ARTRealtimeChannel *channel in realtime.channels) {
                [d setValue:channel forKey:channel.name];
            }
            XCTAssertEqual([[d allKeys] count], 3);
            XCTAssertEqualObjects([d valueForKey:@"channel"], c1);
            XCTAssertEqualObjects([d valueForKey:@"channel2"], c2);
            XCTAssertEqualObjects([d valueForKey:@"channel3"], c3);
        }
        [realtime.channels release:c3.name cb:^(ARTErrorInfo *errorInfo) {
            NSMutableDictionary * d = [[NSMutableDictionary alloc] init];
            for (ARTRealtimeChannel *channel in realtime.channels) {
                [d setValue:channel forKey:channel.name];
            }
            XCTAssertEqual([[d allKeys] count], 2);
            XCTAssertEqualObjects([d valueForKey:@"channel"], c1);
            XCTAssertEqualObjects([d valueForKey:@"channel2"], c2);
        }];
        
        [exp fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testGetSameChannelWithParams {
    XCTestExpectation *exp = [self expectationWithDescription:@"testGetChannels"];
    NSString * channelName = @"channel";
    NSString * firstMessage = @"firstMessage";
    NSString * secondMessage = @"secondMessage";
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *c1 = [realtime.channels get:channelName];
        NSData * ivSpec = [[NSData alloc] initWithBase64EncodedString:@"HO4cYSP8LybPYBPZPHQOtg==" options:0];
        
        NSData * keySpec = [[NSData alloc] initWithBase64EncodedString:@"WUP6u0K7MXI5Zeo0VppPwg==" options:0];
        ARTCipherParams * params =[[ARTCipherParams alloc] initWithAlgorithm:@"aes" key:keySpec keyLength:[keySpec length] iv:ivSpec];
        ARTRealtimeChannel *c2 = [realtime.channels get:channelName options:[[ARTChannelOptions alloc] initEncrypted:true cipherParams:params]];
        [c1 publish:nil data:firstMessage cb:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [c2 publish:nil data:secondMessage cb:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
            }];
        }];
        __block int messageCount =0;
        [c1 subscribe:^(ARTMessage * message) {
            if(messageCount ==0) {
                XCTAssertEqualObjects([message data], firstMessage);
            }
            else if(messageCount ==1) {
                XCTAssertEqualObjects([message data], secondMessage);
                [exp fulfill];
            }
            messageCount++;
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testAttachFails {
    XCTestExpectation *exp = [self expectationWithDescription:@"testAttachFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel on:^(ARTErrorInfo *errorInfo) {
                    if (channel.state == ARTRealtimeChannelAttached) {
                        [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                    }
                }];
                [channel attach];
            }
            else if(state == ARTRealtimeFailed) {
                [channel attach:^(ARTErrorInfo *errorInfo) {
                    XCTAssert(errorInfo);
                    XCTAssertEqual(errorInfo.code, 90000);
                    [exp fulfill];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testDetachFails {
    XCTestExpectation *exp = [self expectationWithDescription:@"testDetachFails"];
    [ARTTestUtil testRealtime:^(ARTRealtime *realtime) {
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:@"attach"];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel on:^(ARTErrorInfo *errorInfo) {
                    if (channel.state == ARTRealtimeChannelAttached) {
                        [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
                    }
                }];
                [channel attach];
            }
            else if(state == ARTRealtimeFailed) {
                [channel detach:^(ARTErrorInfo *errorInfo) {
                    XCTAssert(errorInfo);
                    XCTAssertEqual(errorInfo.code, 90000);
                    [exp fulfill];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void) testClientIdPreserved {
    NSString *firstClientId = @"firstClientId";
    NSString *channelName = @"channelName";

    XCTestExpectation *exp1 = [self expectationWithDescription:@"testClientIdPreserved1"];
    XCTestExpectation *exp2 = [self expectationWithDescription:@"testClientIdPreserved2"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] withDebug:NO cb:^(ARTClientOptions *options) {
        // First instance
        options.clientId = firstClientId;
        ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime = realtime;
        ARTRealtimeChannel *channel = [realtime.channels get:channelName];

        // Second instance
        options.clientId = @"secondClientId";
        ARTRealtime *realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = realtime2;
        ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];

        __block NSUInteger attached = 0;
        // Channel 1
        [channel on:^(ARTErrorInfo *errorInfo) {
            if (channel.state == ARTRealtimeChannelAttached) {
                attached++;
            }
        }];

        // Channel 2
        [channel2 on:^(ARTErrorInfo *errorInfo) {
            if (channel2.state == ARTRealtimeChannelAttached) {
                attached++;
            }
        }];

        [channel2.presence subscribe:^(ARTPresenceMessage *message) {
            XCTAssertEqualObjects(message.clientId, firstClientId);
            [channel2 off];
            [exp1 fulfill];
        }];

        waitForWithTimeout(&attached, @[channel, channel2], 20.0);

        // Enters "firstClientId"
        [channel.presence enter:@"First Client" cb:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            [exp2 fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
