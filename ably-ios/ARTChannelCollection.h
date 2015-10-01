//
//  ARTChannelCollection.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTChannel;
@class ARTChannelOptions;

@interface ARTChannelCollection : NSObject<NSFastEnumeration>

- (BOOL)exists:(NSString *)channelName;
- (ARTChannel *)get:(NSString *)channelName;
- (ARTChannel *)get:(NSString *)channelName options:(ARTChannelOptions *)options;
- (void)releaseChannel:(ARTChannel *)channel;

@end
