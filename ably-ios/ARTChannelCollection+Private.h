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
    __GENERIC(NSMutableDictionary, NSString *, ARTChannel *) *_channels; //FIXME: remove underscore
}

@property (nonatomic, readonly) NSMutableDictionary *channels;
@property (readonly, nonatomic, weak) ARTRest *rest;

@end

ART_ASSUME_NONNULL_END
