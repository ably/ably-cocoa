//
//  ARTRealtimeChannels.h
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTRealtimeChannels_h
#define ARTRealtimeChannels_h

#import "ARTChannels.h"
#import "ARTRealtimeChannel.h"
#import "ARTRealtime.h"
#import "CompatibilityMacros.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannels : NSObject<NSFastEnumeration>

- (instancetype)initWithRealtime:(ARTRealtime *)realtime;

// We copy this from the parent class and replace ChannelType by ARTRealtimeChannel * because
// Swift ignores Objective-C generics and thinks this is returning an id, failing to compile.
// Thus, we can't make ARTRealtimeChannels inherit from ARTChannels; we have to compose them instead.
- (BOOL)exists:(NSString *)name;
- (ARTRealtimeChannel *)get:(NSString *)name;
- (ARTRealtimeChannel *)get:(NSString *)name options:(ARTChannelOptions *)options;
- (void)release:(NSString *)name callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable))errorInfo;
- (void)release:(NSString *)name;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTRealtimeChannels_h */
