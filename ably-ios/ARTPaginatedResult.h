//
//  ARTPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTStatus.h>

@interface ARTPaginatedResult : NSObject {
    @protected
    NSArray *_items;
    BOOL _hasFirst;
    BOOL _hasCurrent;
    BOOL _hasNext;
}

@property (nonatomic, strong, readonly) NSArray *items;

@property (nonatomic, readonly) BOOL hasFirst;
@property (nonatomic, readonly) BOOL hasCurrent;
@property (nonatomic, readonly) BOOL hasNext;

@property (nonatomic, readonly) BOOL isLast;

typedef void(^ARTPaginatedResultCallback)(ARTStatus *status, ARTPaginatedResult *result);

- (void)first:(ARTPaginatedResultCallback)callback;
- (void)current:(ARTPaginatedResultCallback)callback;
- (void)next:(ARTPaginatedResultCallback)callback;

@end
