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

@protocol ARTHTTPExecutor;

@class ARTRestChannels;
@class ARTClientOptions;
@class ARTAuth;
@class ARTCancellable;
@class ARTStatsQuery;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRest : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)tokenId;

- (void)time:(ARTTimeCallback)callback;

- (NSError *__art_nullable)stats:(ARTStatsCallback)callback;
- (NSError *__art_nullable)stats:(art_nullable ARTStatsQuery *)query callback:(ARTStatsCallback)callback;
- (BOOL)statsWithError:(NSError *__art_nullable *__art_nullable)errorPtr callback:(ARTStatsCallback)callback;
- (BOOL)stats:(art_nullable ARTStatsQuery *)query error:(NSError *__art_nullable *__art_nullable)errorPtr callback:(ARTStatsCallback)callback;

@property (nonatomic, strong, readonly) ARTRestChannels *channels;
@property (nonatomic, strong, readonly) ARTAuth *auth;

@end

ART_ASSUME_NONNULL_END
