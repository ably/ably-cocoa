//
//  ARTPushChannel.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTPush.h"

@class ARTChannel;
@class ARTPushChannelSubscription;
@class ARTPaginatedResult;

@protocol ARTHTTPAuthenticatedExecutor;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannel : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor withChannel:(ARTChannel *)channel;

- (void)subscribe;
- (void)subscribeDevice:(ARTDeviceId *)deviceId;
- (void)subscribeClient:(NSString *)clientId;

- (void)unsubscribe;
- (void)unsubscribeDevice:(ARTDeviceId *)deviceId;
- (void)unsubscribeClient:(NSString *)clientId;

- (void)subscriptions:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *_Nullable, ARTErrorInfo *_Nullable))callback;

@end

NS_ASSUME_NONNULL_END
