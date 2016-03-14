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

@property (nonatomic, strong, readonly) __GENERIC(NSArray, ItemType) *items;
@property (nonatomic, readonly) BOOL hasNext;
@property (nonatomic, readonly) BOOL isLast;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (void)first:(void (^)(__GENERIC(ARTPaginatedResult, ItemType) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback;
- (void)next:(void (^)(__GENERIC(ARTPaginatedResult, ItemType) *__art_nullable result, ARTErrorInfo *__art_nullable error))callback;

@end

ART_ASSUME_NONNULL_END
