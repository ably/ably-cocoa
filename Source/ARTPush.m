#import "ARTPush+Private.h"
#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"
#import "ARTRest+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTEventEmitter.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#import "ARTPushActivationStateMachine+Private.h"
#endif
#import "ARTPushAdmin.h"
#import "ARTPushActivationEvent.h"
#import "ARTClientOptions+Private.h"
#import "ARTPushAdmin+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTDeviceStorage.h"
#import "ARTRealtime+Private.h"
#import "ARTInternalLog.h"

@implementation ARTPush {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTPushInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (ARTPushAdmin *)admin {
    return [[ARTPushAdmin alloc] initWithInternal:_internal.admin queuedDealloc:_dealloc];
}

#if TARGET_OS_IOS

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest; {
    return [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken rest:rest];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken realtime:realtime];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest; {
    return [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error rest:rest];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error realtime:realtime];
}

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest; {
    return [ARTPushInternal didRegisterForLocationNotificationsWithDeviceToken:deviceToken rest:rest];
}

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didRegisterForLocationNotificationsWithDeviceToken:deviceToken realtime:realtime];
}

+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error rest:(ARTRest *)rest; {
    return [ARTPushInternal didFailToRegisterForLocationNotificationsWithError:error rest:rest];
}

+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didFailToRegisterForLocationNotificationsWithError:error realtime:realtime];
}

- (void)activate {
    [_internal activate];
}

- (void)deactivate {
    [_internal deactivate];
}

#endif

@end

@implementation ARTPushInternal {
    __weak ARTRestInternal *_rest; // weak because rest owns self
    ARTInternalLog *_logger;
    ARTPushActivationStateMachine *_activationMachine;
    NSLock *_activationMachineLock;
}

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger {
    if (self = [super init]) {
        _rest = rest;
        _logger = logger;
        _admin = [[ARTPushAdminInternal alloc] initWithRest:rest logger:logger];
        _activationMachine = nil;
        _activationMachineLock = [[NSLock alloc] init];
        _activationMachineLock.name = @"ActivationMachineLock";
    }
    return self;
}

- (dispatch_queue_t)queue {
    return _rest.queue;
}

#if TARGET_OS_IOS

- (void)getActivationMachine:(void (^)(ARTPushActivationStateMachine *const))block {
    if (!block) {
        [NSException raise:NSInvalidArgumentException
                    format:@"block is nil."];
    }

    if (![_activationMachineLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:60]]) {
        block(nil);
        return;
    }

    void (^callbackWithUnlock)(ARTPushActivationStateMachine *const machine) = ^(ARTPushActivationStateMachine *machine) {
        [self->_activationMachineLock unlock];
        block(machine);
    };

    if (_activationMachine == nil) {
        const id<ARTPushRegistererDelegate, NSObject> delegate = _rest.options.pushRegistererDelegate;
        if (delegate) {
            callbackWithUnlock([self createActivationStateMachineWithDelegate:delegate]);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                // -[UIApplication delegate] is an UI API call, so needs to be called from main thread.
                const id legacyDelegate = UIApplication.sharedApplication.delegate;
                [self createActivationStateMachineWithDelegate:legacyDelegate
                                             completionHandler:^(ARTPushActivationStateMachine *const machine) {
                    callbackWithUnlock(machine);
                }];
            });
        }
    }
    else {
        callbackWithUnlock(_activationMachine);
    }
}

- (void)createActivationStateMachineWithDelegate:(const id<ARTPushRegistererDelegate, NSObject>)delegate
                               completionHandler:(void (^const)(ARTPushActivationStateMachine *_Nonnull))block {
    dispatch_async(self.queue, ^{
        block([self createActivationStateMachineWithDelegate:delegate]);
    });
}

- (ARTPushActivationStateMachine *)createActivationStateMachineWithDelegate:(const id<ARTPushRegistererDelegate, NSObject>)delegate {
    if (_activationMachine) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"_activationMachine already set."];
    }
    
    _activationMachine = [[ARTPushActivationStateMachine alloc] initWithRest:self->_rest delegate:delegate logger:_logger];
    return _activationMachine;
}

- (ARTPushActivationStateMachine *)activationMachine {
    if (![_activationMachineLock tryLock]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Failed to immediately acquire lock for internal testing purposes."];
    }
    
    ARTPushActivationStateMachine *const machine = _activationMachine;
    if (!machine) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"There is no activation machine for internal testing purposes."];
    }
    
    [_activationMachineLock unlock];
    
    return machine;
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData restInternal:(ARTRestInternal *)rest {
    ARTLogDebug(rest.logger_onlyForUseInClassMethodsAndTests, @"ARTPush: device token data received: %@", [deviceTokenData base64EncodedStringWithOptions:0]);
    [rest setAndPersistAPNSDeviceTokenData:deviceTokenData tokenType:ARTAPNSDeviceDefaultTokenType];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken restInternal:realtime.rest];
    }];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken restInternal:rest];
    }];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error restInternal:(ARTRestInternal *)rest {
    ARTLogError(rest.logger_onlyForUseInClassMethodsAndTests, @"ARTPush: device token not received (%@)", [error localizedDescription]);
    [rest.push getActivationMachine:^(ARTPushActivationStateMachine *stateMachine) {
        [stateMachine sendEvent:[ARTPushActivationEventGettingPushDeviceDetailsFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
    }];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error restInternal:realtime.rest];
    }];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error restInternal:rest];
    }];
}

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceTokenData restInternal:(ARTRestInternal *)rest {
    ARTLogDebug(rest.logger_onlyForUseInClassMethodsAndTests, @"ARTPush: location push device token data received: %@", [deviceTokenData base64EncodedStringWithOptions:0]);
    [rest setAndPersistAPNSDeviceTokenData:deviceTokenData tokenType:ARTAPNSDeviceLocationTokenType];
}

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didRegisterForLocationNotificationsWithDeviceToken:deviceToken restInternal:realtime.rest];
    }];
}

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didRegisterForLocationNotificationsWithDeviceToken:deviceToken restInternal:rest];
    }];
}

+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error restInternal:(ARTRestInternal *)rest {
    ARTLogError(rest.logger_onlyForUseInClassMethodsAndTests, @"ARTPush: location push device token not received (%@)", [error localizedDescription]);
    [rest.push getActivationMachine:^(ARTPushActivationStateMachine *stateMachine) {
        [stateMachine sendEvent:[ARTPushActivationEventGettingPushDeviceDetailsFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
    }];
}

+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didFailToRegisterForLocationNotificationsWithError:error restInternal:realtime.rest];
    }];
}

+ (void)didFailToRegisterForLocationNotificationsWithError:(NSError *)error rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didFailToRegisterForLocationNotificationsWithError:error restInternal:rest];
    }];
}

- (void)activate {
    [self getActivationMachine:^(ARTPushActivationStateMachine *stateMachine) {
        [stateMachine sendEvent:[ARTPushActivationEventCalledActivate new]];
    }];
}

- (void)deactivate {
    [self getActivationMachine:^(ARTPushActivationStateMachine *stateMachine) {
        [stateMachine sendEvent:[ARTPushActivationEventCalledDeactivate new]];
    }];
}

#endif

@end
