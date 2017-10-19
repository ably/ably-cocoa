//
//  ARTRealtime.h
//  ably-ios
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
@class ARTProtocolMessage;
@class ARTRealtimeChannels;

NS_ASSUME_NONNULL_BEGIN

#define ART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))

#pragma mark - ARTRealtime

@interface ARTRealtime : NSObject

@property (nonatomic, strong, readonly) ARTConnection *connection;
@property (nonatomic, strong, readonly) ARTRealtimeChannels *channels;
@property (readonly, getter=getAuth) ARTAuth *auth;
@property (readonly, nullable, getter=getClientId) NSString *clientId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/** 
Instance the Ably library using a key only. This is simply a convenience constructor for the simplest case of instancing the library with a key for basic authentication and no other options.
:param key; String key (obtained from application dashboard)
*/
- (instancetype)initWithKey:(NSString *)key;

- (instancetype)initWithToken:(NSString *)token;

/**
Instance the Ably library with the given options.
:param options: see ARTClientOptions for options
*/
- (instancetype)initWithOptions:(ARTClientOptions *)options;

- (void)time:(void (^)(NSDate *_Nullable, NSError *_Nullable))cb;
- (void)ping:(void (^)(ARTErrorInfo *_Nullable))cb;

- (BOOL)stats:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback;
- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)connect;
- (void)close;

@end

NS_ASSUME_NONNULL_END
