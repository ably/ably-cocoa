//
//  ARTPushAdmin.h
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTPushDeviceRegistrations;
@class ARTPushChannelSubscriptions;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushAdmin : NSObject

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) ARTPushDeviceRegistrations* deviceRegistrations;
@property (nonatomic, readonly) ARTPushChannelSubscriptions* channelSubscriptions;

@end

NS_ASSUME_NONNULL_END
