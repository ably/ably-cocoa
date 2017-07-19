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
#import "ARTEventEmitter.h"
#import "ARTTypes.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTConnection ()

- (NSString *)id_nosync;
- (NSString *)key_nosync;
- (int64_t)serial_nosync;
- (ARTRealtimeConnectionState)state_nosync;
- (ARTErrorInfo *)errorReason_nosync;
- (NSString *)recoveryKey_nosync;

@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTConnectionStateChange *> *eventEmitter;
@property(weak, nonatomic) ARTRealtime* realtime;

@end

@interface ARTConnection (Private)

- (void)setId:(NSString *__art_nullable)newId;
- (void)setKey:(NSString *__art_nullable)key;
- (void)setSerial:(int64_t)serial;
- (void)setState:(ARTRealtimeConnectionState)state;
- (void)setErrorReason:(ARTErrorInfo *__art_nullable)errorReason;

- (void)emit:(ARTRealtimeConnectionEvent)event with:(ARTConnectionStateChange *)data;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTConnection_Private_h */
