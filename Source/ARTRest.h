//
//  ARTRest.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"
#import "ARTRestChannels.h"
#import "ARTLocalDevice.h"

@protocol ARTHTTPExecutor;

@class ARTRestChannels;
@class ARTClientOptions;
@class ARTAuth;
@class ARTPush;
@class ARTCancellable;
@class ARTStatsQuery;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRest : NSObject

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
- (instancetype)initWithToken:(NSString *)tokenId;

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

- (void)time:(void (^)(NSDate *__art_nullable, NSError *__art_nullable))callback;

- (BOOL)stats:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *__art_nullable, ARTErrorInfo *__art_nullable))callback;
- (BOOL)stats:(art_nullable ARTStatsQuery *)query callback:(void (^)(__GENERIC(ARTPaginatedResult, ARTStats *) *__art_nullable, ARTErrorInfo *__art_nullable))callback error:(NSError *__art_nullable *__art_nullable)errorPtr;

@property (nonatomic, strong, readonly) ARTRestChannels *channels;
@property (nonatomic, strong, readonly) ARTAuth *auth;
@property (nonatomic, strong, readonly) ARTPush *push;
#ifdef TARGET_OS_IOS
@property (nonnull, nonatomic, readonly, getter=device) ARTLocalDevice *device;
#endif

@end

ART_ASSUME_NONNULL_END
