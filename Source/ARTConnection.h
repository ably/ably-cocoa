//
//  ARTConnection.h
//  ably
//
//  Created by Ricardo Pereira on 30/10/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTTypes.h"
#import "ARTEventEmitter.h"

@class ARTRealtime;
@class ARTEventEmitter;

ART_ASSUME_NONNULL_BEGIN

@interface ARTConnection: NSObject

@property (art_nullable, readonly, strong, nonatomic) NSString *id;
@property (art_nullable, readonly, strong, nonatomic) NSString *key;
@property (art_nullable, readonly, getter=getRecoveryKey) NSString *recoveryKey;
@property (readonly, assign, nonatomic) int64_t serial;
@property (readonly, assign, nonatomic) ARTRealtimeConnectionState state;
@property (art_nullable, readonly, strong, nonatomic) ARTErrorInfo *errorReason;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime;

- (void)connect;
- (void)close;
- (void)ping:(void (^)(ARTErrorInfo *__art_nullable))cb;

ART_EMBED_INTERFACE_EVENT_EMITTER(ARTRealtimeConnectionState, ARTConnectionStateChange *)

@end

ART_ASSUME_NONNULL_END
