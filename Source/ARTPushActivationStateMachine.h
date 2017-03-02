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

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init:(id<ARTHTTPAuthenticatedExecutor>)httpExecutor;

- (void)sendEvent:(ARTPushActivationEvent *)event;

@end

@interface ARTPushActivationStateMachine (Protected)
- (void)deviceRegistration:(nullable ARTErrorInfo *)error;
- (void)deviceUpdateRegistration:(nullable ARTErrorInfo *)error;
- (void)deviceUnregistration:(nullable ARTErrorInfo *)error;
- (void)callActivatedCallback:(nullable ARTErrorInfo *)error;
- (void)callDeactivatedCallback:(nullable ARTErrorInfo *)error;
- (void)callUpdateFailedCallback:(nullable ARTErrorInfo *)error;
@end

NS_ASSUME_NONNULL_END
