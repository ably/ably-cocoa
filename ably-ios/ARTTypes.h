//
//  ARTTypes.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTStatus.h"

typedef void (^ARTStatusCallback)(ARTStatus status);

@protocol ARTCancellable

- (void)cancel;

@end

@interface ARTIndirectCancellable : NSObject <ARTCancellable>

@property (readwrite, strong, nonatomic) id<ARTCancellable> cancellable;
@property (readonly, assign, nonatomic) BOOL isCancelled;

- (instancetype)init;
- (instancetype)initWithCancellable:(id<ARTCancellable>)cancellable;
- (void)cancel;

@end
