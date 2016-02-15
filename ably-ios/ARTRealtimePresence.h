//
//  ARTRealtimePresence.h
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRestPresence.h"
#import "ARTDataQuery.h"
#import "ARTEventEmitter.h"

@class ARTRealtimeChannel;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceQuery : ARTPresenceQuery

@property (readwrite, nonatomic) BOOL waitForSync;

@end

@interface ARTRealtimePresence : ARTRestPresence

@property (readonly, getter=isSyncComplete) BOOL syncComplete;

- (instancetype)initWithChannel:(ARTRealtimeChannel *)channel;

- (void)get:(ARTRealtimePresenceQuery *)query cb:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;

- (void)enter:(id __art_nullable)data;
- (void)enter:(id __art_nullable)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (void)update:(id __art_nullable)data;
- (void)update:(id __art_nullable)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (void)leave:(id __art_nullable)data;
- (void)leave:(id __art_nullable)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (void)enterClient:(NSString *)clientId data:(id __art_nullable)data;
- (void)enterClient:(NSString *)clientId data:(id __art_nullable)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (void)updateClient:(NSString *)clientId data:(id __art_nullable)data;
- (void)updateClient:(NSString *)clientId data:(id __art_nullable)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (void)leaveClient:(NSString *)clientId data:(id __art_nullable)data;
- (void)leaveClient:(NSString *)clientId data:(id __art_nullable)data cb:(art_nullable void (^)(ARTErrorInfo *__art_nullable))cb;

- (__GENERIC(ARTEventListener, ARTPresenceMessage *) *)subscribe:(void (^)(ARTPresenceMessage *message))cb;
- (__GENERIC(ARTEventListener, ARTPresenceMessage *) *)subscribe:(ARTPresenceAction)action cb:(void (^)(ARTPresenceMessage *message))cb;
- (void)unsubscribe;
- (void)unsubscribe:(__GENERIC(ARTEventListener, ARTPresenceMessage *) *)listener;
- (void)unsubscribe:(ARTPresenceAction)action listener:(__GENERIC(ARTEventListener, ARTPresenceMessage *) *)listener;

- (NSError *__art_nullable)history:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;
- (NSError *__art_nullable)history:(art_nullable ARTRealtimeHistoryQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;
- (BOOL)historyWithError:(NSError *__art_nullable *__art_nullable)errorPtr callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;
- (BOOL)history:(art_nullable ARTRealtimeHistoryQuery *)query error:(NSError *__art_nullable *__art_nullable)errorPtr callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *__art_nullable result, NSError *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
