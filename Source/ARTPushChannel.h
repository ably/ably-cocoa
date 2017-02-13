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

@protocol ARTHTTPAuthenticatedExecutor;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannel : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor withChannel:(ARTChannel *)channel;

- (void)subscribeForDevice:(ARTDeviceId *)deviceId;
- (void)subscribeForClientId:(NSString *)clientId;

- (void)unsubscribeForDevice:(ARTDeviceId *)deviceId;
- (void)unsubscribeForClientId:(NSString *)clientId;

@end

NS_ASSUME_NONNULL_END
