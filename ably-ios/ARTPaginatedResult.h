//
//  ARTPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTPaginatedResult : NSObject

typedef void(^ARTPaginatedResultCallback)(ARTPaginatedResult *__nullable result, NSError *__nullable error);

@property (nonatomic, strong, readonly) NSArray *items;

@property (nonatomic, readonly) BOOL hasFirst;
@property (nonatomic, readonly) BOOL hasCurrent;
@property (nonatomic, readonly) BOOL hasNext;

@property (nonatomic, readonly) BOOL isLast;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (void)first:(ARTPaginatedResultCallback)callback;
- (void)current:(ARTPaginatedResultCallback)callback;
- (void)next:(ARTPaginatedResultCallback)callback;

@end

NS_ASSUME_NONNULL_END
