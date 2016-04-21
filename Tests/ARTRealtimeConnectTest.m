//
//  ARTRealtimeConnectTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTRealtime+Private.h"
#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTLog.h"
#import "ARTEventEmitter.h"
#import "ARTRealtimeChannel.h"

@interface ARTRealtimeConnectTest : XCTestCase

@end

@implementation ARTRealtimeConnectTest


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConnectText {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [expectation fulfill];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectPing {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnected) {
            [realtime.connection ping:^(ARTErrorInfo *error) {
                XCTAssertNil(error);
                [expectation fulfill];
            }];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectStateChange {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.autoConnect = false;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block bool connectingHappened = false;
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if (state == ARTRealtimeConnecting) {
            XCTAssertTrue(realtime.connection.id == nil);
            XCTAssertTrue(realtime.connection.key == nil);
            connectingHappened = true;
        }
        else if(state == ARTRealtimeConnected) {
            XCTAssertTrue(realtime.connection.id != nil);
            XCTAssertTrue(realtime.connection.key != nil);
            XCTAssertTrue(connectingHappened);
            [expectation fulfill];
        }
    }];
    [realtime connect];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectStateChangeClose {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.autoConnect = false;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block bool closingHappened = false;
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
        if(state == ARTRealtimeConnected) {
            [realtime close];
        }
        else if(state == ARTRealtimeClosing) {
            closingHappened = true;
        }
        else if(state == ARTRealtimeClosed) {
            XCTAssertTrue(closingHappened);
            XCTAssertEqual([realtime.connection state], state);
            [expectation fulfill];
        }
    }];
    [realtime connect];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectionSerial {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.autoConnect = false;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
    
        if(state == ARTRealtimeConnected) {
            XCTAssertEqual(realtime.connection.serial, -1);
            ARTRealtimeChannel *c =[realtime.channels get:@"chan"];
            [c publish:nil data:@"message" callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertEqual(realtime.connection.serial, 0);
                [c publish:nil data:@"message2" callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertEqual(realtime.connection.serial, 1);
                    [expectation fulfill];
                }];
                XCTAssertEqual(realtime.connection.serial, 0); //confirms that serial only updates after an ack
            }];
            [c attach];
        }
    }];
    [realtime connect];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectAfterClose {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block int connectionCount = 0;
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
    
        if (state == ARTRealtimeConnected) {
            connectionCount++;
            if(connectionCount == 1) {
                [realtime close];
            }
            else if( connectionCount == 2) {
                [expectation fulfill];
            }
        }
        if (state == ARTRealtimeClosed && connectionCount == 1) {
            [realtime connect];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectingFromClosing {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block bool connectHappened = false;
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
    
        if (state == ARTRealtimeConnected) {
            if (connectHappened) {
                [expectation fulfill];
            }
            else {
                connectHappened = true;
                [realtime close];
            }
        }
        else if (state == ARTRealtimeClosed) {
            [realtime connect];
        }
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectStates {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.autoConnect = false;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block bool gotInitialized =false;
    __block bool gotConnecting =false;
    __block bool gotConnected =false;
    __block bool gotDisconnected =false;
    __block bool gotSuspended =false;
    __block bool gotClosing =false;
    __block bool gotClosed =false;
    __block bool gotFailed= false;
    
    [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;

        if(state == ARTRealtimeConnecting) {
            gotConnecting = true;
            if (stateChange.previous == ARTRealtimeInitialized) {
                gotInitialized = true;
            }
        }
        else if(state == ARTRealtimeConnected) {
            if(!gotConnected) {
                gotConnected = true;
                [realtime close];
            }
            else {
                [realtime onDisconnected];
            }
        }
        else if(state == ARTRealtimeDisconnected) {
            gotDisconnected = true;
            [realtime onSuspended];
        }
        else if(state == ARTRealtimeSuspended) {
            gotSuspended = true;
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
        }
        else if(state == ARTRealtimeClosing) {
            gotClosing = true;
            
        }
        else if(state == ARTRealtimeClosed) {
            gotClosed = true;
            [realtime connect];
        }
        else if(state == ARTRealtimeFailed) {
            gotFailed = true;
            XCTAssertTrue(gotInitialized);
            XCTAssertTrue(gotConnecting);
            XCTAssertTrue(gotConnected);
            XCTAssertTrue(gotDisconnected);
            XCTAssertTrue(gotSuspended);
            XCTAssertTrue(gotClosing);
            XCTAssertTrue(gotClosed);
            XCTAssertTrue(gotFailed);
            XCTAssertTrue([realtime.connection state] == ARTRealtimeFailed);
            [expectation fulfill];
        }
    }];
    [realtime connect];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testConnectPingError {
    ARTClientOptions *options = [ARTTestUtil newSandboxApp:self withDescription:__FUNCTION__];
    __weak XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    options.autoConnect = false;
    ARTRealtime *realtime = [[ARTRealtime alloc] initWithOptions:options];
    __block bool hasClosed = false;
    __block id listener = nil;
    listener = [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
        ARTRealtimeConnectionState state = stateChange.current;
    
        if(state == ARTRealtimeConnected) {
            [realtime close];
        }
        if(state == ARTRealtimeClosed) {
            hasClosed = true;
            XCTAssertThrows([realtime.connection ping:^(ARTErrorInfo *e) {}]);
            [realtime onError:[ARTTestUtil newErrorProtocolMessage]];
        }
        if(state == ARTRealtimeFailed) {
            XCTAssertTrue(hasClosed);
            XCTAssertThrows([realtime.connection ping:^(ARTErrorInfo *e) {}]);
            [expectation fulfill];
            [realtime.connection off:listener];
        }
    }];
    [realtime connect];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

@end
