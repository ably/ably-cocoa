//
//  ARTPushChannelSubscription.h
//  Ably
//
//  Created by Ricardo Pereira on 15/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannelSubscription : NSObject

@property (nonatomic, readonly) NSString *deviceId;
@property (nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSString *channelName;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDeviceId:(NSString *)deviceId andChannel:(NSString *)channelName;
- (instancetype)initWithClientId:(NSString *)clientId andChannel:(NSString *)channelName;

@end

NS_ASSUME_NONNULL_END
