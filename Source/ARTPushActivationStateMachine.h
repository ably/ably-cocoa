//
//  ARTPushActivationStateMachine.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTErrorInfo;
@class ARTPushActivationEvent;

@protocol ARTHTTPAuthenticatedExecutor;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushActivationStateMachine : NSObject

- (instancetype)init;

- (void)sendEvent:(ARTPushActivationEvent *)event;

@end

@interface ARTPushActivationStateMachine (Protected)
- (void)deviceRegistration:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor error:(nullable ARTErrorInfo *)error;
- (void)deviceUnregistration:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor error:(nullable ARTErrorInfo *)error;
- (void)callDeactivatedCallback:(nullable ARTErrorInfo *)error;
@end

NS_ASSUME_NONNULL_END
