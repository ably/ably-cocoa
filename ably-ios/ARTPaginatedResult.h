//
//  ARTPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARTStatus.h"

@protocol ARTPaginatedResult

- (id)current;
- (BOOL)hasFirst;
- (BOOL)hasCurrent;
- (BOOL)hasNext;

typedef void (^ARTPaginatedResultCb)(ARTStatus status, id<ARTPaginatedResult> result);
- (void)getFirst:(ARTPaginatedResultCb)cb;
- (void)getCurrent:(ARTPaginatedResultCb)cb;
- (void)getNext:(ARTPaginatedResultCb)cb;

@end
