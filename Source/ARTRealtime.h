//
//  ARTRealtime.h
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>
#import <Ably/ARTRealtimeChannels.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTConnection.h>

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

NS_ASSUME_NONNULL_BEGIN

#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

#pragma mark - ARTRealtime

@protocol ARTRealtimeProtocol <NSObject>

#if TARGET_OS_IOS
@property (readonly) ARTLocalDevice *device;
#endif
@property (readonly, nullable) NSString *clientId;

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

- (void)time:(void (^)(NSDate *_Nullable, NSError *_Nullable))cb;
- (void)ping:(void (^)(ARTErrorInfo *_Nullable))cb;

- (BOOL)stats:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback;
- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)connect;
- (void)close;

@end

@interface ARTRealtime : NSObject <ARTRealtimeProtocol>

@property (readonly) ARTConnection *connection;
@property (readonly) ARTRealtimeChannels *channels;
@property (readonly) ARTPush *push;
@property (readonly) ARTAuth *auth;

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

@end

NS_ASSUME_NONNULL_END
