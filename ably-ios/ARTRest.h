//
//  ARTRest.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ably.h"

@class ARTCancellable;
@class ARTPaginatedResult;
@class ARTStatsQuery;
@class ARTClientOptions;
@class ARTAuth;
@class ARTChannel;
@class ARTChannelCollection;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRest : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithLogger:(ARTLog *)logger andOptions:(ARTClientOptions *)options;
- (instancetype)initWithKey:(NSString *)key;

- (void)time:(void(^)(NSDate *__nullable time, NSError *__nullable error))callback;
- (void)stats:(nullable ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult /* <ARTStats *> */ *__nullable result, NSError *__nullable error))callback;

- (id<ARTCancellable>)internetIsUp:(void (^)(bool isUp))cb;

@property (nonatomic, strong, readonly) ARTLog *logger;
@property (nonatomic, strong, readonly) ARTChannelCollection *channels;
@property (nonatomic, strong, readonly) ARTAuth *auth;
@property (nonatomic, strong, readonly) ARTClientOptions *options;

@end

NS_ASSUME_NONNULL_END
