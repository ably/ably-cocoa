//
//  ARTPushChannel.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTPush.h"
#import "ARTHttp.h"
#import "ARTChannel.h"

@class ARTPushChannelSubscription;
@class ARTPaginatedResult;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannel : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(ARTRest *)rest withChannel:(ARTChannel *)channel;

- (void)subscribeDevice;
- (void)subscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;
- (void)subscribeClient;
- (void)subscribeClient:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;

- (void)unsubscribeDevice;
- (void)unsubscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;
- (void)unsubscribeClient;
- (void)unsubscribeClient:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;

- (void)listSubscriptions:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *_Nullable, ARTErrorInfo *_Nullable))callback;
- (void)listSubscriptions:(NSDictionary<NSString *, NSString *> *_Nullable)params callback:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *_Nullable, ARTErrorInfo *_Nullable))callback;

@end

NS_ASSUME_NONNULL_END
