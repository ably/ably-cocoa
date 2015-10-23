//
//  ARTChannel+Private.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTChannel.h"
#import "ARTLog.h"

@protocol ARTPayloadEncoder;

ART_ASSUME_NONNULL_BEGIN

@interface ARTChannel() {
@public
    id<ARTPayloadEncoder> _payloadEncoder;
}

@property (nonatomic, strong, art_null_resettable) ARTChannelOptions *options;

- (void)internalPostMessages:(id)data callback:(art_nullable ARTErrorCallback)callback;

@end

ART_ASSUME_NONNULL_END
