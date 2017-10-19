//
//  ARTHttp.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTHTTPExecutor

@property (nonatomic, weak) ARTLog *logger;

- (void)executeRequest:(NSURLRequest *)request completion:(nullable void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback;

@end

@interface ARTHttp : NSObject<ARTHTTPExecutor>

@property (nonatomic, weak) ARTLog *logger;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)init:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
