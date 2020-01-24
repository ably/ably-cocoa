//
//  ARTRealtimeChannelOptions.h
//  Ably-iOS
//
//  Created by Ricardo Pereira on 24/01/2020.
//  Copyright © 2020 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTChannelOptions.h>

typedef NS_OPTIONS(NSUInteger, ARTChannelMode) {
    ARTChannelModePresence = 0,
    ARTChannelModePublish = 1 << 0,
    ARTChannelModeSubscribe = 1 << 1,
    ARTChannelModePresenceSubscribe = 1 << 2
};

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannelOptions : ARTChannelOptions

@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *params;
@property (nonatomic, assign) ARTChannelMode modes;

@end

NS_ASSUME_NONNULL_END
