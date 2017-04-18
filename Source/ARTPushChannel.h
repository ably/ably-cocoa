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

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannel : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(ARTRestChannel *)channel;

#ifdef TARGET_OS_IOS
- (void)subscribeDevice;
- (void)subscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;
#endif
- (void)subscribeClient:(NSString *)clientId;
- (void)subscribeClient:(NSString *)clientId callback:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;

#ifdef TARGET_OS_IOS
- (void)unsubscribeDevice;
- (void)unsubscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;
#endif
- (void)unsubscribeClient:(NSString *)clientId;
- (void)unsubscribeClient:(NSString *)clientId callback:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;

- (void)getSubscriptions:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *_Nullable, ARTErrorInfo *_Nullable))callback;

@end

NS_ASSUME_NONNULL_END
