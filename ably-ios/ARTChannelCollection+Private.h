//
//  ARTChannelCollection+Private.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTChannel;
@class ARTChannelOptions;

NS_ASSUME_NONNULL_BEGIN

@interface ARTChannelCollection() {
@protected
    NSMutableDictionary /* <NSString *, ARTChannel *> */ *_channels;
}

@property (nonatomic, readonly) NSMutableDictionary *channels;

- (ARTChannel *)_createChannelWithName:(NSString *)name options:(nullable ARTChannelOptions *)options;

@end

NS_ASSUME_NONNULL_END
