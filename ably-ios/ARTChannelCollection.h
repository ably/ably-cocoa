//
//  ARTChannelCollection.h
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

@interface ARTChannelCollection : NSObject<NSFastEnumeration>

@property (nonatomic, readonly) __GENERIC(NSMutableDictionary, NSString *, ARTRestChannel *) *channels;

- (instancetype)initWithRest:(ARTRest *)rest;

- (BOOL)exists:(NSString *)channelName;
- (ARTRestChannel *)get:(NSString *)channelName;
- (ARTRestChannel *)get:(NSString *)channelName options:(ARTChannelOptions *)options;
- (void)releaseChannel:(ARTRestChannel *)channel;

@end
