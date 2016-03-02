//
//  ARTPresenceMap.h
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

@class ARTPresenceMessage;

ART_ASSUME_NONNULL_BEGIN

/// Used to maintain a list of members present on a channel
@interface ARTPresenceMap : NSObject

/// List of members.
/// The key is the clientId and the value is the latest relevant ARTPresenceMessage for that clientId.
@property (readonly, atomic, getter=getMembers) __GENERIC(NSDictionary, NSString *, ARTPresenceMessage *) *members;

@property (readwrite, nonatomic, assign) int64_t syncSerial;

- (ARTPresenceMessage *)getClient:(NSString *) clientId;
- (void)put:(ARTPresenceMessage *) message;

- (void)startSync;
- (void)endSync;
- (BOOL)isSyncComplete;
- (BOOL)stillSyncing;

typedef void(^VoidCb)();
- (void)syncMessageProcessed;
- (void)onSync:(VoidCb) cb;

@end

ART_ASSUME_NONNULL_END
