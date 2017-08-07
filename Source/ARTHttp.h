//
//  ARTHttp.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"
#import "ARTLog.h"

@class ARTErrorInfo;

ART_ASSUME_NONNULL_BEGIN

@protocol ARTHTTPExecutor

@property (nonatomic, weak) ARTLog *logger;

- (void)executeRequest:(NSURLRequest *)request completion:(art_nullable void (^)(NSHTTPURLResponse *__art_nullable, NSData *__art_nullable, NSError *__art_nullable))callback;

@end

@interface ARTHttp : NSObject<ARTHTTPExecutor>

@property (nonatomic, weak) ARTLog *logger;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)init:(dispatch_queue_t)queue;

@end

ART_ASSUME_NONNULL_END
