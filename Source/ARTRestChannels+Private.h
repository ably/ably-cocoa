//
//  ARTRestChannels+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 21/07/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#ifndef ARTRestChannels_Private_h
#define ARTRestChannels_Private_h

#import "ARTRestChannels.h"

@class ARTRestChannel;

ART_ASSUME_NONNULL_BEGIN

@interface ARTRestChannels ()

- (ARTRestChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions * _Nullable)options addPrefix:(BOOL)addPrefix;

@end

ART_ASSUME_NONNULL_END


#endif /* ARTRestChannels_Private_h */
