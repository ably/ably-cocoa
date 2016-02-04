//
//  ARTChannel+Private.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTChannel.h"
#import "ARTLog.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTChannel()

@property (readonly, getter=getLogger) ARTLog *logger;
@property (nonatomic, strong, art_null_resettable) ARTChannelOptions *options;
@property (nonatomic, strong, readonly) ARTDataEncoder *dataEncoder;

- (ARTMessage *__art_nonnull)encodeMessageIfNeeded:(ARTMessage *__art_nonnull)message;
- (void)internalPostMessages:(id)data callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
