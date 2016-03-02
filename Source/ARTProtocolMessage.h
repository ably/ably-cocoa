//
//  ARTProtocolMessage.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTMessage.h"
#import "ARTPresenceMessage.h"

@class ARTConnectionDetails;
@class ARTErrorInfo;
@class ARTMessage;
@class ARTPresenceMessage;

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

ART_ASSUME_NONNULL_BEGIN

/**
 A message sent and received over the Realtime protocol.
 A ProtocolMessage always relates to a single channel only, but can contain multiple individual Messages or PresenceMessages.
 ProtocolMessages are serially numbered on a connection.
 */
@interface ARTProtocolMessage : NSObject

@property (readwrite, assign, nonatomic) ARTProtocolMessageAction action;
@property (readwrite, assign, nonatomic) int count;
@property (art_nullable, readwrite, strong, nonatomic) ARTErrorInfo *error;
@property (art_nullable, readwrite, strong, nonatomic) NSString *id;
@property (art_nullable, readwrite, strong, nonatomic) NSString *channel;
@property (art_nullable, readwrite, strong, nonatomic) NSString *channelSerial;
@property (art_nullable, readwrite, strong, nonatomic) NSString *connectionId;
@property (art_nullable, readwrite, strong, nonatomic, getter=getConnectionKey) NSString *connectionKey;
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (readwrite, assign, nonatomic) int64_t msgSerial;
@property (art_nullable, readwrite, strong, nonatomic) NSDate *timestamp;
@property (art_nullable, readwrite, strong, nonatomic) __GENERIC(NSArray, ARTMessage *) *messages;
@property (art_nullable, readwrite, strong, nonatomic) __GENERIC(NSArray, ARTPresenceMessage *) *presence;
@property (readwrite, assign, nonatomic) int64_t flags;
@property (art_nullable, readwrite, nonatomic) ARTConnectionDetails *connectionDetails;

@end

ART_ASSUME_NONNULL_END
