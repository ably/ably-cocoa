//
//  ARTChannel.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ably.h"

@class ARTChannelOptions;
@class ARTPresence;
@class ARTMessage;
@class ARTPaginatedResult;
@class ARTDataQuery;

NS_ASSUME_NONNULL_BEGIN

@interface ARTChannel : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) ARTPresence *presence;

- (void)publish:(nullable id)payload callback:(nullable ARTErrorCallback)callback;

- (void)publish:(nullable id)payload name:(nullable NSString *)name callback:(nullable ARTErrorCallback)callback;

- (void)publishMessage:(ARTMessage *)message callback:(nullable ARTErrorCallback)callback;

- (void)publishMessages:(NSArray /* <ARTMessage *> */ *)messages callback:(nullable ARTErrorCallback)callback;

- (void)history:(nullable ARTDataQuery *)query callback:(void(^)(ARTPaginatedResult /* <ARTMessage *> */ *__nullable result, NSError *__nullable error))callback;

@end

NS_ASSUME_NONNULL_END
