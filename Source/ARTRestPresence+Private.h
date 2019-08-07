//
//  ARTRestPresence+Private.h
//  ably
//
//  Created by Toni Cárdenas on 7/4/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTRestPresence.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRestChannelInternal;

@interface ARTRestPresence ()

- (instancetype)initWithChannel:(ARTRestChannelInternal *)channel;

@end

NS_ASSUME_NONNULL_END
