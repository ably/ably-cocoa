#import <Ably/ARTPush.h>
#import <Ably/ARTPushAdmin+Private.h>
#import <Ably/ARTQueuedDealloc.h>

@class ARTPushActivationStateMachine;
@class ARTRestInternal;
@protocol ARTPushRegistererDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushInternal : NSObject

@property (nonatomic, readonly) ARTPushAdminInternal *admin;
@property (readonly) dispatch_queue_t queue;

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

#if TARGET_OS_IOS
- (void)getActivationMachine:(void (^)(ARTPushActivationStateMachine *))block;

/// Direct access to _activationMachine var for internal testing.
/// Throws an exception if there is no activation machine or it could not be locked immediately.
@property (readonly) ARTPushActivationStateMachine *activationMachine;

/// Create the _activationMachine manually with a custom delegate for internal testing.
- (ARTPushActivationStateMachine *)createActivationStateMachineWithDelegate:(id<ARTPushRegistererDelegate, NSObject>)delegate;
#endif

#if TARGET_OS_IOS

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;

+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

- (void)activate;

- (void)deactivate;

#endif

@end

@interface ARTPush ()

@property (nonatomic, readonly) ARTPushInternal *internal;

- (instancetype)initWithInternal:(ARTPushInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
