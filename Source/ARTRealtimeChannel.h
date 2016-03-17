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
- (void)attach:(art_nullable void (^)(ARTErrorInfo *__art_nullable))callback;

- (void)detach;
- (void)detach:(art_nullable void (^)(ARTErrorInfo *__art_nullable))callback;

- (__GENERIC(ARTEventListener, ARTMessage *) *__art_nullable)subscribe:(void (^)(ARTMessage *message))callback;
- (__GENERIC(ARTEventListener, ARTMessage *) *__art_nullable)subscribeWithAttachCallback:(art_nullable void (^)(ARTErrorInfo *__art_nullable))onAttach callback:(void (^)(ARTMessage *message))cb;
- (__GENERIC(ARTEventListener, ARTMessage *) *__art_nullable)subscribe:(NSString *)name callback:(void (^)(ARTMessage *message))cb;
- (__GENERIC(ARTEventListener, ARTMessage *) *__art_nullable)subscribe:(NSString *)name onAttach:(art_nullable void (^)(ARTErrorInfo *__art_nullable))onAttach callback:(void (^)(ARTMessage *message))cb;

- (void)unsubscribe;
- (void)unsubscribe:(__GENERIC(ARTEventListener, ARTMessage *) *__art_nullable)listener;
- (void)unsubscribe:(NSString *)name listener:(__GENERIC(ARTEventListener, ARTMessage *) *__art_nullable)listener;

- (void)history:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback;
- (BOOL)history:(art_nullable ARTRealtimeHistoryQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

ART_EMBED_INTERFACE_EVENT_EMITTER(ARTChannelEvent, ARTErrorInfo *)

@end

ART_ASSUME_NONNULL_END
