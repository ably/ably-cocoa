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

@protocol ARTHTTPExecutor;

@class ARTChannelCollection;
@class ARTClientOptions;
@class ARTAuth;
@class ARTCancellable;
@class ARTPaginatedResult;
@class ARTStatsQuery;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRest : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options;
- (instancetype)initWithKey:(NSString *)key;

- (void)time:(void(^)(NSDate *__art_nullable time, NSError *__art_nullable error))callback;
- (void)stats:(art_nullable ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTStats *> */ *__art_nullable result, NSError *__art_nullable error))callback;

- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp))cb;

@property (nonatomic, strong, readonly) ARTLog *logger;
@property (nonatomic, strong, readonly) ARTChannelCollection *channels;
@property (nonatomic, strong, readonly) ARTAuth *auth;
@property (nonatomic, strong, readonly) ARTClientOptions *options;

@end

ART_ASSUME_NONNULL_END
