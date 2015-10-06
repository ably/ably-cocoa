//
//  ARTChannelCollection+Private.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@class ARTChannel;
@class ARTChannelOptions;

ART_ASSUME_NONNULL_BEGIN

@interface ARTChannelCollection() {
@protected
    NSMutableDictionary /* <NSString *, ARTChannel *> */ *_channels;
}

@property (nonatomic, readonly) NSMutableDictionary *channels;

- (ARTChannel *)_createChannelWithName:(NSString *)name options:(art_nullable ARTChannelOptions *)options;

@end

ART_ASSUME_NONNULL_END
