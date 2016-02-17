//
//  ARTRealtimeChannel.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"
#import "ARTRestChannel.h"
#import "ARTPresenceMessage.h"
#import "ARTEventEmitter.h"
#import "ARTRealtimePresence.h"
#import "ARTDataQuery.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannel : ARTRestChannel

@property (readwrite, assign, nonatomic) ARTRealtimeChannelState state;
@property (readonly, strong, nonatomic, art_nullable) ARTErrorInfo *errorReason;
@property (readonly, getter=getPresence) ARTRealtimePresence *presence;

- (void)attach;
- (void)attach:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (void)detach;
- (void)detach:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (__GENERIC(ARTEventListener, ARTMessage *) *)subscribe:(void (^)(ARTMessage *message))cb;
- (__GENERIC(ARTEventListener, ARTMessage *) *)subscribe:(NSString *)name cb:(void (^)(ARTMessage *message))cb;

- (void)unsubscribe;
- (void)unsubscribe:(__GENERIC(ARTEventListener, ARTMessage *) *)listener;
- (void)unsubscribe:(NSString *)name listener:(__GENERIC(ARTEventListener, ARTMessage *) *)listener;

- (BOOL)history:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *__art_nullable result, NSError *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;
- (BOOL)history:(art_nullable ARTRealtimeHistoryQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *__art_nullable result, NSError *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

ART_EMBED_INTERFACE_EVENT_EMITTER(ARTRealtimeChannelState, ARTErrorInfo *)

@end

ART_ASSUME_NONNULL_END
