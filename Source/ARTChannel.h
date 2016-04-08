//
//  ARTChannel.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTDataEncoder.h"
#import "ARTLog.h"

@class ARTChannelOptions;
@class ARTMessage;
@class __GENERIC(ARTPaginatedResult, ItemType);
@class ARTDataQuery;

ART_ASSUME_NONNULL_BEGIN

@interface ARTChannel : NSObject

@property (nonatomic, strong, readonly) NSString *name;

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options andLogger:(ARTLog *)logger;

- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data;
- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback;

- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data clientId:(NSString *)clientId;
- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data clientId:(NSString *)clientId callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback;

- (void)publish:(__GENERIC(NSArray, ARTMessage *) *)messages;
- (void)publish:(__GENERIC(NSArray, ARTMessage *) *)messages callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback;

- (void)history:(void(^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
