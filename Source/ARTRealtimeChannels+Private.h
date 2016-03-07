
//
//  ARTRealtimeChannels+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 07/03/2016.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtimeChannels.h"

@class ARTRealtimeChannel;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannels ()

@property (nonatomic, readonly, getter=getCollection) __GENERIC(NSMutableDictionary, NSString *, ARTRealtimeChannel *) *collection;

@end

ART_ASSUME_NONNULL_END
