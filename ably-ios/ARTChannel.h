//
//  ARTChannel.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@class ARTChannelOptions;
@class ARTMessage;
@class ARTPaginatedResult;
@class ARTDataQuery;

ART_ASSUME_NONNULL_BEGIN

@interface ARTChannel : NSObject

@property (nonatomic, strong, readonly) NSString *name;

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options;

- (void)publish:(art_nullable id)payload callback:(art_nullable ARTErrorCallback)callback;
- (void)publish:(art_nullable id)payload name:(art_nullable NSString *)name callback:(art_nullable ARTErrorCallback)callback;

- (void)publishMessage:(ARTMessage *)message callback:(art_nullable ARTErrorCallback)callback;
- (void)publishMessages:(__GENERIC(NSArray, ARTMessage *) *)messages callback:(art_nullable ARTErrorCallback)callback;

- (void)history:(art_nullable ARTDataQuery *)query callback:(void(^)(ARTPaginatedResult /* <ARTMessage *> */ *__art_nullable result, NSError *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
