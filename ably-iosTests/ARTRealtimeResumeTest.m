//
//  ARTRealtimeResumeTest.m
//  ably-ios
//
//  Created by vic on 16/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ARTMessage.h"
#import "ARTOptions.h"
#import "ARTPresenceMessage.h"

#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTRealtime+Private.h"

@interface ARTRealtimeResumeTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
}
@end

@implementation ARTRealtimeResumeTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _realtime = nil;
    _realtime2 = nil;
    [super tearDown];
}

- (void)withRealtime:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        [ARTTestUtil setupApp:[ARTTestUtil jsonRealtimeOptions] cb:^(ARTOptions *options) {
            if (options) {
                _realtime = [[ARTRealtime alloc] initWithOptions:options];
                _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
            }
            cb(_realtime);
        }];
        return;
    }
    cb(_realtime);
}

//only for use after calling withRealtime
- (void)withRealtime2:(void (^)(ARTRealtime *realtime))cb {
    cb(_realtime2);
}
/**
  create 2 connections, each connected to the same channel.
 disonnect and reconnect one of the connections, then use that channel
 to send and recieve message. verify all messages sent and recieved ok.
 */

-(void)testSimple {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testSimple"];
    NSString * channelName = @"resumeChannel";
    [self withRealtime:^(ARTRealtime *realtime) {
        [self withRealtime2:^(ARTRealtime *realtime2) {
            
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
            ARTRealtimeChannel *channel = [realtime channel:channelName];
            [channel subscribe:^(ARTMessage * message) {
                if([[message content] isEqualToString:@"c2message"])
                {
                   // NSLog(@"got c2messge");
                    [channel publish:@"c1SaysThanksForTheMessage" cb:^(ARTStatus status) {
                       // NSLog(@"send c1 thanks message");
                        XCTAssertEqual(ARTStatusOk, status);
                        
                    }];
                }
            }];
            [channel2 subscribe:^(ARTMessage * message) {
                if([[message content] isEqualToString:@"c1SaysThanksForTheMessage"])
                {
                   // NSLog(@"c2 recieved the thank you");
                    [expectation fulfill];
                }
            }];
            __block bool  hasAttached = false;
            [realtime2 subscribeToStateChanges:^(ARTRealtimeConnectionState conState2) {
                
               // NSLog(@"testSimple constate...: %@", [ARTRealtime ARTRealtimeStateToStr:conState2]);
                if(conState2 == ARTRealtimeConnected)
                {
                    if(!hasAttached)
                    {
                        hasAttached = true;
                        [realtime2 onError:nil];
                    }
                    else {
                        //successfully detached and reattached. now publish
                        //and check it works.
                        [channel2 attach];
                        [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
                            if(cState == ARTRealtimeChannelAttached)
                            {
                                [channel2 publish:@"c2message" cb:^(ARTStatus status) {
                                    NSLog(@"send c2 message");
                                    XCTAssertEqual(ARTStatusOk, status);
                                }];
                            }
                        }];
                    }
                }
                if(hasAttached &&  conState2 ==ARTRealtimeFailed)
                {
                    NSLog(@"detached indeed");
                    [realtime2 connect];
                }
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
XCTestExpectation *expectation = [self expectationWithDescription:@"testSimple"];
NSString * channelName = @"resumeChannel";
[self withRealtime:^(ARTRealtime *realtime) {
    [self withRealtime:^(ARTRealtime *realtime2) {
        ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];
        ARTRealtimeChannel *channel = [realtime channel:channelName];
        [channel subscribe:^(ARTMessage * message) {
        }];
        [channel2 subscribe:^(ARTMessage * message) {
        }];
    }];
}];

*/



//TODO rm maybe.
-(void)testDisconnected {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testDisconnected"];
    [self withRealtime:^(ARTRealtime *realtime) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
   
    NSString * channelName = @"resumeChannel";
    [self withRealtime:^(ARTRealtime *realtime) {
 
         XCTestExpectation *expectChannel1Down = [self expectationWithDescription:@"expectChannel1Down"];
        ARTRealtimeChannel *channel = [realtime channel:channelName];

        [channel subscribeToStateChanges:^(ARTRealtimeChannelState cState, ARTStatus reason) {
            NSLog(@"channel 1 is %lu", cState);
           
        }];
        __block bool connected=false;
        [realtime subscribeToStateChanges:^(ARTRealtimeConnectionState cState) {
            NSLog(@"realtime state is %lu", cState);
            if(cState == ARTRealtimeConnected)
            {
                if(!connected)
                {
                    connected = true;
                    [realtime onError:nil];
                }
                else
                {
                    NSLog(@"realtime has reconnected");
                    
                }
            }
            if(connected &&cState == ARTRealtimeFailed)
            {
                [expectChannel1Down fulfill];
            }
            
        }];

        NSLog(@"channel is down??");
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        NSLog(@"channel is down");

     
            XCTestExpectation *expectChan2Published = [self expectationWithDescription:@"expectChan2Published"];
        [self withRealtime2:^(ARTRealtime *realtime2) {

            NSLog(@"withrealtime2 started");
            [realtime2 subscribeToStateChanges:^(ARTRealtimeConnectionState cState2) {
                NSLog(@"realtime2 is %lu", cState2);
            }];
            ARTRealtimeChannel *channel2 = [realtime2 channel:channelName];

            [channel2 subscribeToStateChanges:^(ARTRealtimeChannelState chanState2, ARTStatus reason) {
                NSLog(@"chan state is %lu", chanState2);
                if(chanState2 == ARTRealtimeChannelAttached)
                {
                    [channel2 publish:@"chan2 says something" cb:^(ARTStatus status) {
                        XCTAssertEqual(ARTStatusOk, status);
                        [expectChan2Published fulfill];
                    }];
                    
                }
            }];
            [channel2 attach];
            
            [channel2 subscribe:^(ARTMessage * message) {
                NSLog(@"channel 2 got %@", [message content]);
                if([[message content] isEqualToString:@"sentWhileC2IsDown"])
                {
                    NSLog(@"recieved message on c2 sent while c2 was down");
                }
            }];

            
            NSLog(@"channel2 is published???");
          //  [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
            NSLog(@"channel2 is published");
            [realtime connect];
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
        XCTestExpectation *expectChannel1GotMessage = [self expectationWithDescription:@"expectChannel1GotMessage"];
        [channel subscribe:^(ARTMessage * message) {
            [expectChannel1GotMessage fulfill];
            NSLog(@"channel 1 recieved message %@", [message content]);
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    }];
}

-(void)testMultipleChannel {
    XCTFail(@"TODO write test");
}

- (void)testResumeMultipleInterval {
    XCTFail(@"TODO write test");
}

@end
