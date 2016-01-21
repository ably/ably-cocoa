//
//  ARTPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTStatus.h"

ART_ASSUME_NONNULL_BEGIN

@interface __GENERIC(ARTPaginatedResult, ItemType) : NSObject

// FIXME: review with Stats callback
typedef void(^ARTPaginatedResultCallback)(__GENERIC(ARTPaginatedResult, ItemType) *__art_nullable result, NSError *__art_nullable error);

@property (nonatomic, strong, readonly) __GENERIC(NSArray, ItemType) *items;

@property (nonatomic, readonly) BOOL hasFirst;
@property (nonatomic, readonly) BOOL hasCurrent;
@property (nonatomic, readonly) BOOL hasNext;

@property (nonatomic, readonly) BOOL isLast;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (void)first:(ARTPaginatedResultCallback)callback;
- (void)current:(ARTPaginatedResultCallback)callback;
- (void)next:(ARTPaginatedResultCallback)callback;

@end

ART_ASSUME_NONNULL_END
