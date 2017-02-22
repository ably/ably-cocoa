//
//  ARTPushActivationStateMachine.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTLog;

@protocol ARTHTTPAuthenticatedExecutor;

NS_ASSUME_NONNULL_BEGIN

// TODO: this should not be available to user's
@interface ARTPushActivationStateMachine : NSObject

@property (nonatomic, readonly) id<ARTHTTPAuthenticatedExecutor> httpExecutor;
@property (nonatomic, readonly) ARTLog *logger;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor;

@end

NS_ASSUME_NONNULL_END
