//
//  ARTRealtime.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"
#import "ARTRealtimeChannels.h"
#import "ARTEventEmitter.h"
#import "ARTConnection.h"

@class ARTStatus;
@class ARTMessage;
@class ARTClientOptions;
@class ARTStatsQuery;
@class ARTRealtimeChannel;
@class ARTPresenceMessage;
@class ARTErrorInfo;
@class ARTCipherParams;
@class ARTPresence;
@class ARTPresenceMap;
@class ARTEventEmitter;
@class ARTRealtimeChannel;
@class ARTAuth;
@class ARTPush;
@class ARTProtocolMessage;
@class ARTRealtimeChannels;

ART_ASSUME_NONNULL_BEGIN

#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

#pragma mark - ARTRealtime

@interface ARTRealtime : NSObject

@property (nonatomic, strong, readonly) ARTConnection *connection;
@property (nonatomic, strong, readonly) ARTRealtimeChannels *channels;
@property (readonly) ARTAuth *auth;
@property (readonly) ARTPush *push;
#ifdef TARGET_OS_IOS
@property (nonnull, nonatomic, readonly, getter=getDevice) ARTLocalDevice *device;
#endif
@property (readonly, art_nullable, getter=getClientId) NSString *clientId;

- (instancetype)init NS_UNAVAILABLE;

/**
 Instance the Ably library with the given options.
 :param options: see ARTClientOptions for options
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/** 
Instance the Ably library using a key only. This is simply a convenience constructor for the simplest case of instancing the library with a key for basic authentication and no other options.
:param key; String key (obtained from application dashboard)
*/
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)token;

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

- (void)time:(void (^)(NSDate *__art_nullable, NSError *__art_nullable))cb;
- (void)ping:(void (^)(ARTErrorInfo *__art_nullable))cb;

- (BOOL)stats:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *__art_nullable, ARTErrorInfo *__art_nullable))callback;
- (BOOL)stats:(art_nullable ARTStatsQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *__art_nullable, ARTErrorInfo *__art_nullable))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

- (void)connect;
- (void)close;

@end

ART_ASSUME_NONNULL_END
