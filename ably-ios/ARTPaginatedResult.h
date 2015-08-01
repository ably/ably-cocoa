//
//  ARTPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ably/ARTStatus.h>

@protocol ARTPaginatedResult

- (id)currentItems;
- (BOOL)hasFirst;
- (BOOL)hasCurrent;
- (BOOL)hasNext;

typedef void (^ARTPaginatedResultCb)(ARTStatus *status, id<ARTPaginatedResult> result);
- (void)first:(ARTPaginatedResultCb)cb;
- (void)current:(ARTPaginatedResultCb)cb;
- (void)next:(ARTPaginatedResultCb)cb;

@end
