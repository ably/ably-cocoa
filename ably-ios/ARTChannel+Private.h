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
    __weak ARTLog *_logger;
}

@property (nonatomic, strong, null_resettable) ARTChannelOptions *options;

- (instancetype)initWithName:(NSString *)name presence:(ARTPresence *)presence options:(art_nullable ARTChannelOptions *)options;

- (void)_postMessages:(id)payload callback:(art_nullable ARTErrorCallback)callback;

@end

ART_ASSUME_NONNULL_END
