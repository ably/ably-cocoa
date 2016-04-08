//
//  ARTRestChannels.m
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRestChannels.h"
#import "ARTChannels+Private.h"
#import "ARTRestChannel+Private.h"

@interface ARTRestChannels ()

@property (weak, nonatomic) ARTRest *rest;

@end

@interface ARTRestChannels () <ARTChannelsDelegate>
@end

@implementation ARTRestChannels {
    ARTChannels *_channels;
}

- (instancetype)initWithRest:(ARTRest *)rest {
    if (self = [super init]) {
        _channels = [[ARTChannels alloc] initWithDelegate:self];
        _rest = rest;
    }
    return self;
}

- (id)makeChannel:(NSString *)name options:(ARTChannelOptions *)options {
    return [[ARTRestChannel alloc] initWithName:name withOptions:options andRest:_rest];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len {
    return [_channels countByEnumeratingWithState:state objects:buffer count:len];
}

- (ARTRestChannel *)get:(NSString *)name {
    return [_channels get:name];
}

- (ARTRestChannel *)get:(NSString *)name options:(ARTChannelOptions *)options {
    return [_channels get:name options:options];
}

- (BOOL)exists:(NSString *)name {
    return [_channels exists:name];
}

- (void)release:(NSString *)name {
    [_channels release:name];
}

@end
