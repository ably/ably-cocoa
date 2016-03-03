//
//  ARTRealtimePresenceHistory.m
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

#import "ARTRealtime.h"
#import "ARTTestUtil.h"
#import "ARTRest.h"
#import "ARTLog.h"
#import "ARTRealtimePresence.h"
#import "ARTRealtimeChannel.h"
#import "ARTEventEmitter.h"
#import "ARTPaginatedResult.h"
#import "ARTDataQuery.h"
#import "ARTRealtime+Private.h"

@interface ARTRealtimePresenceHistoryTest : XCTestCase
{
    ARTRealtime * _realtime;
    ARTRealtime * _realtime2;
    ARTRealtime * _realtime3;
}
@end

@implementation ARTRealtimePresenceHistoryTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
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
    if (_realtime3) {
        [ARTTestUtil removeAllChannels:_realtime3];
        [_realtime3 resetEventEmitter];
        [_realtime3 close];
    }
    _realtime3 = nil;
    [super tearDown];
}
-(NSString *) getClientId {
    return @"theClientId";
}

- (void)withRealtimeClientId:(void (^)(ARTRealtime *realtime))cb {
    if (!_realtime) {
        ARTClientOptions * options = [ARTTestUtil clientOptions];
        options.clientId = [self getClientId];
        [ARTTestUtil setupApp:options callback:^(ARTClientOptions *options) {
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

//only for use after withRealtimeClientId.
- (void)withRealtimeClientId2:(void (^)(ARTRealtime *realtime))cb {
    cb(_realtime2);
}

-(NSString *) enter1Str {
    return @"client_entered1";
}

-(NSString *) enter2Str {
    return @"client_entered2";
}

-(NSString *) updateStr {
    return @"client_updated";
}

-(NSString *) channelName {
    return @"persisted:runTestChannelName";
}

-(void) runTestLimit:(int)limit forwards:(bool)forwards callback:(ARTPaginatedResultCallback)cb {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:[self channelName]];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:[self enter1Str] callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    //second enter gets treated as an update.
                    [channel.presence enter:[self enter2Str] callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel.presence update:[self updateStr] callback:^(ARTErrorInfo *errorInfo2) {
                            XCTAssertNil(errorInfo2);

                            ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                            query.direction = forwards ? ARTQueryDirectionForwards : ARTQueryDirectionBackwards;
                            query.limit = limit;

                            [channel.presence history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                                cb(result, error);
                                [expectation fulfill];
                            } error:nil];
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}


- (void)testPresenceHistory {
    NSString * presenceEnter = @"client_has_entered";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testSimpleText"];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);

                    [channel.presence history:[[ARTRealtimeHistoryQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        NSArray *messages = [result items];
                        XCTAssertEqual(1, messages.count);
                        ARTPresenceMessage *m0 = messages[0];
                        XCTAssertEqualObjects(presenceEnter, [m0 data]);
                        [expectation fulfill];
                    } error:nil];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testForward {
    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"persisted:testSimpleText"];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter1 callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [channel.presence enter:presenceEnter2 callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel.presence update:presenceUpdate callback:^(ARTErrorInfo *errorInfo2) {
                            XCTAssertNil(errorInfo2);

                            ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                            query.direction = ARTQueryDirectionForwards;

                            [channel.presence history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                                 XCTAssert(!error);
                                 NSArray *messages = [result items];
                                 XCTAssertEqual(3, messages.count);
                                 ARTPresenceMessage *m0 = messages[0];
                                 ARTPresenceMessage *m1 = messages[1];
                                 ARTPresenceMessage *m2 = messages[2];
                                 
                                 XCTAssertEqual(m0.action, ARTPresenceEnter);
                                 XCTAssertEqualObjects(presenceEnter1, [m0 data]);
    
                                 XCTAssertEqualObjects(presenceEnter2, [m1 data]);
                                 XCTAssertEqual(m1.action, ARTPresenceUpdate);
                                 XCTAssertEqualObjects(presenceUpdate, [m2 data]);
                                 XCTAssertEqual(m2.action, ARTPresenceUpdate);
                                 [expectation fulfill];
                            } error:nil];
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

- (void)testSecondChannel {

    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    NSString * channelName = @"testSecondChannel";

    XCTestExpectation *expectation = [self expectationWithDescription:@"testSingleSendEchoText"];
    [self withRealtimeClientId:^(ARTRealtime *realtime1) {
        ARTRealtimeChannel *channel = [realtime1.channels get:channelName];
       
    
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached)
            {
                [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
                    ARTRealtimeChannel *channel2 = [realtime2.channels get:channelName];
                    [channel2.presence enter:presenceEnter1 callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel.presence enter:presenceEnter2 callback:^(ARTErrorInfo *errorInfo) {
                            XCTAssertNil(errorInfo);
                            [channel2.presence update:presenceUpdate callback:^(ARTErrorInfo *errorInfo) {
                                XCTAssertNil(errorInfo);

                                ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                                query.direction = ARTQueryDirectionForwards;

                                [channel.presence history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                                     XCTAssert(!error);
                                     NSArray *messages = [result items];
                                     XCTAssertEqual(3, messages.count);
                                     ARTPresenceMessage *m0 = messages[0];
                                     ARTPresenceMessage *m1 = messages[1];
                                     ARTPresenceMessage *m2 = messages[2];
                                     
                                     XCTAssertEqual(m0.action, ARTPresenceEnter);
                                     XCTAssertEqualObjects(presenceEnter1, [m0 data]);
                                     
                                     XCTAssertEqualObjects(presenceEnter2, [m1 data]);
                                     XCTAssertEqual(m1.action, ARTPresenceEnter);
                                     XCTAssertEqualObjects(presenceUpdate, [m2 data]);
                                     XCTAssertEqual(m2.action, ARTPresenceUpdate);
                                     [expectation fulfill];
                                 } error:nil];
                            }];
                            
                        }];
                    }];
                }];
            }
        }];
        [channel attach];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}



- (void)testWaitTextBackward {
    NSString * presenceEnter1 = @"client_has_entered";
    NSString * presenceEnter2 = @"client_has_entered2";
    NSString * presenceUpdate= @"client_has_updated";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testWaitTextBackward"];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:presenceEnter1 callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);

                    [channel.presence enter:presenceEnter2 callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel.presence update:presenceUpdate callback:^(ARTErrorInfo *errorInfo2) {
                            XCTAssertNil(errorInfo2);

                            ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                            query.direction = ARTQueryDirectionBackwards;

                            [channel.presence history:query callback:^(ARTPaginatedResult *result, NSError *error) {
                                 XCTAssert(!error);
                                 NSArray *messages = [result items];
                                 XCTAssertEqual(3, messages.count);
                                 ARTPresenceMessage *m0 = messages[0];
                                 ARTPresenceMessage *m1 = messages[1];
                                 ARTPresenceMessage *m2 = messages[2];
                                 
                                 XCTAssertEqual(m0.action, ARTPresenceUpdate);
                                 XCTAssertEqualObjects(presenceUpdate, [m0 data]);
                                 
                                 XCTAssertEqualObjects(presenceEnter2, [m1 data]);
                                 XCTAssertEqual(m1.action, ARTPresenceUpdate);
                                 XCTAssertEqualObjects(presenceEnter1, [m2 data]);
                                 XCTAssertEqual(m2.action, ARTPresenceEnter);
                                 [expectation fulfill];
                             } error:nil];
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

-(void) testLimitForward
{
    [self runTestLimit:2 forwards:true callback:^(ARTPaginatedResult *result, NSError *error) {
        XCTAssert(!error);
        NSArray *messages = [result items];
        XCTAssertEqual(2, messages.count);
        XCTAssert([result hasNext]);
        ARTPresenceMessage *m0 = messages[0];
        ARTPresenceMessage *m1 = messages[1];
        
        XCTAssertEqual(m0.action, ARTPresenceEnter);
        XCTAssertEqualObjects([self enter1Str], [m0 data]);
        
        XCTAssertEqualObjects([self enter2Str], [m1 data]);
        XCTAssertEqual(m1.action, ARTPresenceUpdate);
        
        [result next:^(ARTPaginatedResult *result2, NSError *error2) {
            
            NSArray *messages = [result2 items];
            XCTAssertEqual(1, messages.count);
            XCTAssertFalse([result2 hasNext]);
            ARTPresenceMessage *m0 = messages[0];
            XCTAssertEqualObjects([self updateStr], [m0 data]);
            XCTAssertEqual(m0.action, ARTPresenceUpdate);
        }];
    }];
}



- (void)testLimitBackward {
    [self runTestLimit:2 forwards:false callback:^(ARTPaginatedResult *result, NSError *error) {
        XCTAssert(!error);
        NSArray *messages = [result items];
        XCTAssertEqual(2, messages.count);
        XCTAssert([result hasNext]);
        ARTPresenceMessage *m0 = messages[0];
        ARTPresenceMessage *m1 = messages[1];
        
        XCTAssertEqual(m0.action, ARTPresenceUpdate);
        XCTAssertEqualObjects([self updateStr], [m0 data]);
        
        XCTAssertEqualObjects([self enter2Str], [m1 data]);
        XCTAssertEqual(m1.action, ARTPresenceUpdate);
        
        [result next:^(ARTPaginatedResult *result2, NSError *error2) {
            
            NSArray *messages = [result2 items];
            XCTAssertEqual(1, messages.count);
            XCTAssertFalse([result2 hasNext]);
            ARTPresenceMessage *m0 = messages[0];
            XCTAssertEqualObjects([self enter1Str], [m0 data]);
            XCTAssertEqual(m0.action, ARTPresenceEnter);
        }];
    }];
}



-(int) firstBatchSize
{
    return 2;
}
-(int) secondBatchSize
{
    return 3;
}
-(int) thirdBatchSize
{
    return 4;
}


// TODO: consider using a pattern similar to ARTTestUtil testPublish.
-(void) runTestTimeForwards:(bool) forwards limit:(int) limit callback:(ARTPaginatedResultCallback) cb {
    __block long long timeOffset= 0;
    
    XCTestExpectation *e = [self expectationWithDescription:@"getTime"];
    [self withRealtimeClientId:^(ARTRealtime  *realtime) {
        [realtime time:^(NSDate *time, NSError *error) {
            XCTAssert(!error);
            long long serverNow = [time timeIntervalSince1970]*1000;
            long long appNow =[ARTTestUtil nowMilli];
            timeOffset = serverNow - appNow;
            
        }];
        [e fulfill];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:@"testWaitText"];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        XCTestExpectation *firstBatchExpectation= [self expectationWithDescription:@"firstBatchExpectation"];
        
        int firstBatchTotal = [self firstBatchSize];
        int secondBatchTotal = [self secondBatchSize];
        int thirdBatchTotal = [self thirdBatchSize];
    
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:[self enter1Str] callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);

                    __block int numReceived=0;
                    for(int i=0;i < firstBatchTotal; i++)
                    {
                        NSString * str = [NSString stringWithFormat:@"update%d", i];
                        [channel.presence update:str callback:^(ARTErrorInfo *errorInfo) {
                            XCTAssertNil(errorInfo);
                            sleep([ARTTestUtil smallSleep]);
                            numReceived++;
                            if(numReceived == firstBatchTotal) {
                                [firstBatchExpectation fulfill];
                            }
                        }];
                    }
                }];
            }
        }];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];


        sleep([ARTTestUtil bigSleep]);
        long long start = [ARTTestUtil nowMilli] + timeOffset;

        XCTestExpectation * secondBatchExpectation= [self expectationWithDescription:@"secondBatchExpectation"];
        __block int numReceived=0;
        for(int i=0;i < secondBatchTotal; i++) {
            NSString * str = [NSString stringWithFormat:@"second_updates%d", i];
            [channel.presence update:str callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                sleep([ARTTestUtil smallSleep]);
                numReceived++;
                if(numReceived == secondBatchTotal) {
                    [secondBatchExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

        sleep([ARTTestUtil bigSleep]);
        long long end = [ARTTestUtil nowMilli] + timeOffset;


        numReceived = 0;
        XCTestExpectation *thirdBatchExpectation = [self expectationWithDescription:@"thirdBatchExpectation"];
        for(int i=0;i < thirdBatchTotal; i++) {
            NSString * str = [NSString stringWithFormat:@"third_updates%d", i];
            [channel.presence update:str callback:^(ARTErrorInfo *errorInfo) {
                sleep([ARTTestUtil smallSleep]);
                XCTAssertNil(errorInfo);
                numReceived++;
                if(numReceived == thirdBatchTotal) {
                    [thirdBatchExpectation fulfill];
                }
            }];
        }
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

        ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
        query.start = [NSDate dateWithTimeIntervalSince1970:start/1000];
        query.end = [NSDate dateWithTimeIntervalSince1970:end/1000];
        query.limit = limit;
        query.direction = forwards ? ARTQueryDirectionForwards : ARTQueryDirectionBackwards;

        XCTestExpectation *historyExpecation = [self expectationWithDescription:@"historyExpecation"];
        [channel.presence history:query callback:^(ARTPaginatedResult *result, NSError *error) {
            cb(result, error);
            [historyExpecation fulfill];
        } error:nil];
        [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
    }];
}

- (void)testTimeForward {
    [self runTestTimeForwards:true limit:100 callback:^(ARTPaginatedResult *result, NSError *error) {
        XCTAssert(!error);
        XCTAssertFalse([result hasNext]);
        NSArray *page = [result items];
        XCTAssertTrue(page != nil);
        XCTAssertEqual([page count], [self secondBatchSize]);
        for(int i=0;i < [page count]; i++) {
            NSString * goalStr = [NSString stringWithFormat:@"second_updates%d",i];
            ARTPresenceMessage * m = [page objectAtIndex:i];
            XCTAssertEqual(ARTPresenceUpdate, m.action);
            XCTAssertEqualObjects(goalStr, [m data]);
        }
    }];
}

- (void)testTimeBackward {
    [self runTestTimeForwards:false limit:100 callback:^(ARTPaginatedResult *result, NSError *error) {
        XCTAssert(!error);
        XCTAssertFalse([result hasNext]);
        NSArray * page = [result items];
        XCTAssertTrue(page != nil);
        XCTAssertEqual([page count], [self secondBatchSize]);
        int topSize = [self secondBatchSize];
        for(int i=0;i < [page count]; i++) {
            NSString * goalStr = [NSString stringWithFormat:@"second_updates%d",topSize - i -1];
            ARTPresenceMessage * m = [page objectAtIndex:i];
            XCTAssertEqual(ARTPresenceUpdate, m.action);
            XCTAssertEqualObjects(goalStr, [m data]);
        }
    }];
}

- (void)testFromAttach {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self withRealtimeClientId:^(ARTRealtime *realtime) {
        ARTRealtimeChannel *channel = [realtime.channels get:[self channelName]];
        [realtime.connection on:^(ARTConnectionStateChange *stateChange) {
            ARTRealtimeConnectionState state = stateChange.current;
            if (state == ARTRealtimeConnected) {
                [channel attach];
            }
        }];
        [channel on:^(ARTErrorInfo *errorInfo) {
            if(channel.state == ARTRealtimeChannelAttached) {
                [channel.presence enter:[self enter1Str] callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [channel.presence enter:[self enter2Str] callback:^(ARTErrorInfo *errorInfo) {
                        XCTAssertNil(errorInfo);
                        [channel.presence update:[self updateStr] callback:^(ARTErrorInfo *errorInfo2) {
                            XCTAssertNil(errorInfo2);
                            [self withRealtimeClientId2:^(ARTRealtime *realtime2) {
                                ARTRealtimeChannel * channel2 = [realtime2.channels get:[self channelName]];
                                [channel2 on:^(ARTErrorInfo *errorInfo) {
                                    if(channel2.state == ARTRealtimeChannelAttached) {
                                        ARTRealtimeHistoryQuery *query = [[ARTRealtimeHistoryQuery alloc] init];
                                        query.direction = ARTQueryDirectionForwards;
                                        [channel2.presence history:query callback:^(ARTPaginatedResult *c2Result, NSError *error2) {
                                            XCTAssert(!error2);
                                            NSArray *messages = [c2Result items];
                                            XCTAssertEqual(3, messages.count);
                                            XCTAssertFalse([c2Result hasNext]);
                                            ARTPresenceMessage *m0 = messages[0];
                                            ARTPresenceMessage *m1 = messages[1];
                                            ARTPresenceMessage *m2 = messages[2];
                                            
                                            XCTAssertEqual(m0.action, ARTPresenceEnter);
                                            XCTAssertEqualObjects([self enter1Str], [m0 data]);
                                            
                                            XCTAssertEqualObjects([self enter2Str], [m1 data]);
                                            XCTAssertEqual(m1.action, ARTPresenceUpdate);
                                            XCTAssertEqualObjects([self updateStr], [m2 data]);
                                            XCTAssertEqual(m2.action, ARTPresenceUpdate);
                                            [expectation fulfill];
                                        } error:nil];
                                    }
                                }];
                                [channel2 attach];
                            }];
                           
                        }];
                    }];
                }];
            }
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];

}

- (void)testPresenceHistoryMultipleClients {
    NSString * presenceEnter1 = @"enter1";
    NSString * presenceEnter2 = @"enter2";
    NSString * presenceEnter3 = @"enter3";
    
    NSString * channelName = @"chanName";
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [ARTTestUtil setupApp:[ARTTestUtil clientOptions] callback:^(ARTClientOptions *options) {
        options.clientId = [self getClientId];
        _realtime = [[ARTRealtime alloc] initWithOptions:options];
        _realtime2 = [[ARTRealtime alloc] initWithOptions:options];
        _realtime3 = [[ARTRealtime alloc] initWithOptions:options];
        ARTRealtimeChannel * c1 =[_realtime.channels get:channelName];
        [c1.presence enter:presenceEnter1 callback:^(ARTErrorInfo *errorInfo) {
            XCTAssertNil(errorInfo);
            ARTRealtimeChannel * c2 =[_realtime2.channels get:channelName];
            [c2.presence enter:presenceEnter2 callback:^(ARTErrorInfo *errorInfo) {
                XCTAssertNil(errorInfo);
                ARTRealtimeChannel * c3 =[_realtime3.channels get:channelName];
                [c3.presence enter:presenceEnter3 callback:^(ARTErrorInfo *errorInfo) {
                    XCTAssertNil(errorInfo);
                    [c1.presence history:[[ARTRealtimeHistoryQuery alloc] init] callback:^(ARTPaginatedResult *result, NSError *error) {
                        XCTAssert(!error);
                        NSArray *messages = [result items];
                        XCTAssertEqual(3, messages.count);
                        {
                            ARTPresenceMessage *m = messages[0];
                            XCTAssertEqualObjects(presenceEnter3, [m data]);
                        }
                        {
                            ARTPresenceMessage *m = messages[1];
                            XCTAssertEqualObjects(presenceEnter2, [m data]);
                        }
                        {
                            ARTPresenceMessage *m = messages[2];
                            XCTAssertEqualObjects(presenceEnter1, [m data]);
                        }
                        [expectation fulfill];
                    } error:nil];
                }];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:[ARTTestUtil timeout] handler:nil];
}

/*
 //msgpack not implemented yet
- (void)testTypesBinary {
    XCTFail(@"TODO write test");
}


- (void)testWaitBinary {
    XCTFail(@"TODO write test");
}

- (void)testSimpleBinary {
    XCTFail(@"TODO write test");
}

- (void)testWaitBinaryForward {
    XCTFail(@"TODO write test");
}

- (void)testMixedBinaryBackward {
    XCTFail(@"TODO write test");
}

- (void)testMixedBinaryForward {
    XCTFail(@"TODO write test");
}

 */

@end
