//
//  ARTChannels.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"

@class ARTRest;
@class ARTRestChannel;
@class ARTChannelOptions;

@interface __GENERIC(ARTChannels, ChannelType) : NSObject<NSFastEnumeration>

- (BOOL)exists:(NSString *)channelName;
- (ChannelType)get:(NSString *)channelName;
- (ChannelType)get:(NSString *)channelName options:(ARTChannelOptions *)options;
- (void)release:(NSString *)channelName;

@end
