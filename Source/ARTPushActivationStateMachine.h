//
//  ARTPushActivationStateMachine.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTErrorInfo;
@class ARTPushActivationState;
@class ARTPushActivationEvent;
@class ARTRest;

@protocol ARTDeviceStorage;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTPushActivationCurrentStateKey;
extern NSString *const ARTPushActivationPendingEventsKey;

@interface ARTPushActivationStateMachine : NSObject

@property (nonatomic, strong) ARTRest *rest;
@property (nonatomic, readonly) ARTPushActivationState *current;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init:(ARTRest *)rest;
- (instancetype)init:(ARTRest *)rest storage:(id<ARTDeviceStorage>)storage;

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
