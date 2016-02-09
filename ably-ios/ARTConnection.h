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

@property (art_nullable, readonly, getter=getId) NSString *id;
@property (art_nullable, readonly, getter=getKey) NSString *key;
@property (readonly, getter=getSerial) int64_t serial;
@property (readonly, getter=getState) ARTRealtimeConnectionState state;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime;

- (void)connect;
- (void)close;
- (void)ping:(ARTRealtimePingCb)cb;

ART_EMBED_INTERFACE_EVENT_EMITTER(NSNumber *, ARTConnectionStateChange *)

@end

ART_ASSUME_NONNULL_END
