//
//  ARTConnection+Private.h
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTConnection_Private_h
#define ARTConnection_Private_h

#import "ARTConnection.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTConnection (Private)

@property(weak, nonatomic) ARTRealtime* realtime;

- (void)setId:(NSString *__art_nullable)newId;
- (void)setKey:(NSString *__art_nullable)key;
- (void)setSerial:(int64_t)serial;
- (void)setState:(ARTRealtimeConnectionState)state;

- (void)emit:(NSNumber *)event with:(ARTConnectionStateChange *)data;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTConnection_Private_h */
