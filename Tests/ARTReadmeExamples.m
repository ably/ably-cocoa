//
//  ARTReadmeExamples.m
//  ably
//
//  Created by Toni Cárdenas on 9/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ARTTestUtil.h"
#import "ably.h"

@interface ARTReadmeExamples : XCTestCase
@end

@implementation ARTReadmeExamples

- (void)testMakeKeyInstance {
    ARTRealtime* client = [[ARTRealtime alloc] initWithKey:@"xxxx:xxxx"];
    [client.connection close];
}

- (void)testMakeTokenInstance {
    ARTRealtime* client = [[ARTRealtime alloc] initWithToken:@"xxxx"];
    [client.connection close];
}

- (void)testListenToConnectionStateChanges {
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *client) {
        [client.connection on:^(ARTConnectionStateChange *stateChange) {
            switch (stateChange.current) {
                case ARTRealtimeConnected:
                    NSLog(@"connected!");
                    break;
                case ARTRealtimeFailed:
                    NSLog(@"failed! %@", stateChange.reason);
                    break;
                default:
                    break;
            }
        }];
    }];
}

- (void)testNoAutoConnect {
    ARTClientOptions *options = [[ARTClientOptions alloc] initWithKey:@"xxxx:xxxx"];
    options.autoConnect = false;
    ARTRealtime *client = [[ARTRealtime alloc] initWithOptions:options];
    [client.connection connect];
    [client.connection close];
}

- (void)testSubscribeAndPublishingToChannel {
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *client) {
        ARTRealtimeChannel *channel = [client.channels get:@"test"];
        
        [channel subscribe:^(ARTMessage *message) {
            NSLog(@"%@", message.name);
            NSLog(@"%@", message.data);
        }];
        
        [channel subscribe:@"myEvent" callback:^(ARTMessage *message) {
            NSLog(@"%@", message.name);
            NSLog(@"%@", message.data);
        }];
        
        [channel publish:@"greeting" data:@"Hello World!"];

        [channel history:^(ARTPaginatedResult<ARTMessage *> *messagesPage, ARTErrorInfo *error) {
            NSLog(@"%@", messagesPage.items);
        }];
    }];
}

- (void)testQueryingTheHistory {
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *client) {
        ARTRealtimeChannel *channel = [client.channels get:@"test"];

        [channel history:^(ARTPaginatedResult<ARTMessage *> *messagesPage, ARTErrorInfo *error) {
            NSLog(@"%@", messagesPage.items);
            NSLog(@"%@", messagesPage.items.firstObject);
            NSLog(@"%@", messagesPage.items.firstObject.data); // payload for the message
            NSLog(@"%lu", (unsigned long)[messagesPage.items count]); // number of messages in the current page of history
            [messagesPage next:^(ARTPaginatedResult<ARTMessage *> *nextPage, ARTErrorInfo *error) {
                // retrieved the next page in nextPage
            }];
            NSLog(@"%d", messagesPage.hasNext); // true, there are more pages
        }];
    }];
}

- (void)testPresenceOnAChannel {
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    options.clientId = @"foo";
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *client) {
        ARTRealtimeChannel *channel = [client.channels get:@"test"];
        
        [channel.presence enter:@"john.doe" callback:^(ARTErrorInfo *errorInfo) {
            [channel.presence get:^(ARTPaginatedResult<ARTPresenceMessage *> *result, NSError *error) {
                // members is the array of members present
            }];
        }];
    }];
}

- (void)testQueryingThePresenceHistory {
    ARTClientOptions *options = [ARTTestUtil clientOptions];
    [ARTTestUtil testRealtime:options callback:^(ARTRealtime *client) {
        ARTRealtimeChannel *channel = [client.channels get:@"test"];
        
        [channel.presence history:^(ARTPaginatedResult<ARTPresenceMessage *> *presencePage, ARTErrorInfo *error) {
            ARTPresenceMessage *first = (ARTPresenceMessage *)presencePage.items.firstObject;
            NSLog(@"%lu", (unsigned long)first.action); // Any of ARTPresenceEnter, ARTPresenceUpdate or ARTPresenceLeave
            NSLog(@"%@", first.clientId); // client ID of member
            NSLog(@"%@", first.data); // optional data payload of member
            [presencePage next:^(ARTPaginatedResult<ARTPresenceMessage *> *nextPage, ARTErrorInfo *error) {
                // retrieved the next page in nextPage
            }];
        }];
    }];
}

- (void)testMakeRestClientAndChannel {
    ARTRest *client = [[ARTRest alloc] initWithKey:@"xxxx:xxxx"];
    ARTRestChannel *channel = [client.channels get:@"test"];
    channel = channel;
}

- (void)testRestPublishMessage {
    [ARTTestUtil testRest:^(ARTRest *client) {
        ARTRestChannel *channel = [client.channels get:@"test"];
        [channel publish:@"myEvent" data:@"Hello!"];
    }];
}

- (void)testRestQueryingTheHistory {
    [ARTTestUtil testRest:^(ARTRest *client) {
        ARTRestChannel *channel = [client.channels get:@"test"];
        
        [channel history:^(ARTPaginatedResult<ARTMessage *> *messagesPage, ARTErrorInfo *error) {
            NSLog(@"%@", messagesPage.items.firstObject);
            NSLog(@"%@", messagesPage.items.firstObject.data); // payload for the message
            NSLog(@"%lu", (unsigned long)[messagesPage.items count]); // number of messages in the current page of history
            [messagesPage next:^(ARTPaginatedResult<ARTMessage *> *nextPage, ARTErrorInfo *error) {
                // retrieved the next page in nextPage
            }];
            NSLog(@"%d", messagesPage.hasNext); // true, there are more pages
        }];
    }];
}

- (void)testRestPresenceOnAChannel {
    [ARTTestUtil testRest:^(ARTRest *client) {
        ARTRestChannel *channel = [client.channels get:@"test"];

        [channel.presence get:^(ARTPaginatedResult<ARTPresenceMessage *> *membersPage, ARTErrorInfo *error) {
            NSLog(@"%@", membersPage.items.firstObject);
            NSLog(@"%@", membersPage.items.firstObject.data); // payload for the message
            [membersPage next:^(ARTPaginatedResult<ARTMessage *> *nextPage, ARTErrorInfo *error) {
                // retrieved the next page in nextPage
            }];
            NSLog(@"%d", membersPage.hasNext); // true, there are more pages
        }];
    }];
}

- (void)testRestQueryingThePresenceHistory {
    [ARTTestUtil testRest:^(ARTRest *client) {
        ARTRestChannel *channel = [client.channels get:@"test"];
        
        [channel.presence history:^(ARTPaginatedResult<ARTPresenceMessage *> *presencePage, ARTErrorInfo *error) {
            ARTPresenceMessage *first = (ARTPresenceMessage *)presencePage.items.firstObject;
            NSLog(@"%@", first.clientId); // client ID of member
            NSLog(@"%@", first.data); // optional data payload of member
            [presencePage next:^(ARTPaginatedResult<ARTPresenceMessage *> *nextPage, ARTErrorInfo *error) {
                // retrieved the next page in nextPage
            }];
        }];
    }];
}

- (void)testGenerateToken {
    [ARTTestUtil testRest:^(ARTRest *client) {
        [client.auth requestToken:nil withOptions:nil callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
            NSLog(@"%@", tokenDetails.token); // "xVLyHw.CLchevH3hF....MDh9ZC_Q"
            ARTRest *client = [[ARTRest alloc] initWithToken:tokenDetails.token];
            client = client;
        }];
    }];
}

- (void)testFetchingStats {
    [ARTTestUtil testRest:^(ARTRest *client) {
        [client stats:^(ARTPaginatedResult<ARTStats *> *statsPage, ARTErrorInfo *error) {
            NSLog(@"%@", statsPage.items.firstObject);
            [statsPage next:^(ARTPaginatedResult<ARTStats *> *nextPage, ARTErrorInfo *error) {
                // retrieved the next page in nextPage
            }];
        }];
    }];
}

- (void)testFetchingTime {
    [ARTTestUtil testRest:^(ARTRest *client) {
        [client time:^(NSDate *time, NSError *error) {
            NSLog(@"%@", time); // 2016-02-09 03:59:24 +0000
        }];
    }];
}

@end
