//
//  ARTProtocolMessage.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTStatus.h"



typedef NS_ENUM(NSUInteger, ARTProtocolMessageAction) {
    

    ARTProtocolMessageHeartbeat = 0,
    ARTProtocolMessageAck = 1,
    ARTProtocolMessageNack = 2,
    ARTProtocolMessageConnect = 3,
    ARTProtocolMessageConnected = 4,
    ARTProtocolMessageDisconnect = 5,
    ARTProtocolMessageDisconnected = 6,
    ARTProtocolMessageClose = 7,
    ARTProtocolMessageClosed = 8,
    ARTProtocolMessageError = 9,
    ARTProtocolMessageAttach = 10,
    ARTProtocolMessageAttached = 11,
    ARTProtocolMessageDetach = 12,
    ARTProtocolMessageDetached = 13,
    ARTProtocolMessagePresence = 14,
    ARTProtocolMessageMessage = 15,
    ARTProtocolMessageSync = 16,
};

@interface ARTProtocolMessage : NSObject

@property (readwrite, assign, nonatomic) ARTProtocolMessageAction action;
@property (readwrite, assign, nonatomic) int count;
@property (readwrite, strong, nonatomic) ARTErrorInfo * error;
@property (readwrite, strong, nonatomic) NSString *id;
@property (readwrite, strong, nonatomic) NSString *channel;
@property (readwrite, strong, nonatomic) NSString *channelSerial;
@property (readwrite, strong, nonatomic) NSString *connectionId;
@property (readwrite, strong, nonatomic) NSString *connectionKey;
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (readwrite, assign, nonatomic) BOOL hasConnectionSerial;
@property (readwrite, assign, nonatomic) int64_t msgSerial;
@property (readwrite, strong, nonatomic) NSDate *timestamp;
@property (readwrite, strong, nonatomic) NSArray *messages;
@property (readwrite, strong, nonatomic) NSArray *presence;
@property (readonly, assign, nonatomic) BOOL ackRequired;
@property (readwrite, assign, nonatomic) int64_t flags;

-(BOOL) syncInOperation;

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg;

@end
