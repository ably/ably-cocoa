//
//  ARTChannels+Private.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTChannels.h"

@class ARTRestChannel;
@class ARTChannelOptions;

ART_ASSUME_NONNULL_BEGIN

extern NSString* (^__art_nullable ARTChannels_getChannelNamePrefix)();

@protocol ARTChannelsDelegate <NSObject>

- (id)makeChannel:(NSString *)channel options:(ARTChannelOptions *)options;

@end

@interface __GENERIC(ARTChannels, ChannelType) ()

@property (nonatomic, readonly) __GENERIC(NSMutableDictionary, NSString *, ChannelType) *channels;

- (instancetype)initWithDelegate:(id<ARTChannelsDelegate>)delegate;

@end

ART_ASSUME_NONNULL_END
