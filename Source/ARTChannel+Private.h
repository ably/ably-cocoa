//
//  ARTChannel+Private.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Ably/ARTChannel.h>
#import <Ably/ARTLog.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRestInternal;

@interface ARTChannel()

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options rest:(ARTRestInternal *)rest;

@property (readonly, nullable) ARTChannelOptions *options;

@property (readonly, getter=getLogger) ARTLog *logger;
@property (nonatomic, strong, readonly) ARTDataEncoder *dataEncoder;

- (void)internalPostMessages:(id)data callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback;
- (BOOL)exceedMaxSize:(NSArray<ARTBaseMessage *> *)messages;

- (nullable ARTChannelOptions *)options;
- (nullable ARTChannelOptions *)options_nosync;
- (void)setOptions:(ARTChannelOptions *_Nullable)options;
- (void)setOptions_nosync:(ARTChannelOptions *_Nullable)options;

@end

NS_ASSUME_NONNULL_END
