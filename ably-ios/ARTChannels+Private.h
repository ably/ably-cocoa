//
//  ARTChannels+Private.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <ably/ARTChannels.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTChannel() {
@public
    id<ARTPayloadEncoder> _payloadEncoder;
    __weak ARTLog *_logger;
}

@property (nonatomic, strong, null_resettable) ARTChannelOptions *options;

- (instancetype)initWithName:(NSString *)name presence:(ARTPresence *)presence options:(nullable ARTChannelOptions *)options;

- (void)_postMessages:(id)payload callback:(nullable ARTStatusCallback)callback;

@end

@interface ARTChannelCollection() {
@protected
    NSMutableDictionary /* <NSString *, ARTChannel *> */ *_channels;
}

- (ARTChannel *)_createChannelWithName:(NSString *)name options:(nullable ARTChannelOptions *)options;

@end

NS_ASSUME_NONNULL_END