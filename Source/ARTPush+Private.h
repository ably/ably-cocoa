#import <Ably/ARTPush.h>
#import <Ably/ARTPushAdmin+Private.h>
#import "ARTQueuedDealloc.h"

@class ARTPushActivationStateMachine;
@class ARTRestInternal;
@class ARTLog;
@class ARTLocalDevice;
@protocol ARTDeviceStorage;
@protocol ARTPushRegistererDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushInternal : NSObject <ARTPushProtocol>

@property (nonatomic, strong, readonly) ARTPushAdminInternal *admin;
@property (readonly) dispatch_queue_t queue;

@property (nonatomic, strong, readonly) ARTLog *logger;

- (instancetype)init:(ARTRestInternal *)rest;

#if TARGET_OS_IOS

@property (nonatomic) id<ARTDeviceStorage> storage;

@property (nonnull, nonatomic, readonly) ARTLocalDevice *device;
@property (nonnull, nonatomic, readonly) ARTLocalDevice *device_nosync;

- (void)resetSharedDevice;

- (void)getActivationMachine:(void (^)(ARTPushActivationStateMachine *))block;

/// Direct access to _activationMachine var for internal testing.
/// Throws an exception if there is no activation machine or it could not be locked immediately.
@property (readonly) ARTPushActivationStateMachine *activationMachine;

/// Create the _activationMachine manually with a custom delegate for internal testing.
- (ARTPushActivationStateMachine *)createActivationStateMachineWithDelegate:(id<ARTPushRegistererDelegate, NSObject>)delegate;
#endif

@end

@interface ARTPush ()

@property (nonatomic, readonly) ARTPushInternal *internal;

- (instancetype)initWithInternal:(ARTPushInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
