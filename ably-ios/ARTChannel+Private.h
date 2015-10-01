//
//  ARTChannel+Private.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <ably/ARTChannel.h>

@protocol ARTPayloadEncoder;

NS_ASSUME_NONNULL_BEGIN

@interface ARTChannel() {
@public
    id<ARTPayloadEncoder> _payloadEncoder;
    __weak ARTLog *_logger;
}

@property (nonatomic, strong, null_resettable) ARTChannelOptions *options;

- (instancetype)initWithName:(NSString *)name presence:(ARTPresence *)presence options:(nullable ARTChannelOptions *)options;

- (void)_postMessages:(id)payload callback:(nullable ARTErrorCallback)callback;

@end

NS_ASSUME_NONNULL_END
