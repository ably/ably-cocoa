#import "ARTWrapperSDKProxyPush+Private.h"
#import "ARTWrapperSDKProxyPushAdmin+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTWrapperSDKProxyPush ()

@property (nonatomic, readonly) ARTPush *underlyingPush;
@property (nonatomic, readonly) ARTWrapperSDKProxyOptions *proxyOptions;

@end

NS_ASSUME_NONNULL_END

@implementation ARTWrapperSDKProxyPush

- (instancetype)initWithPush:(ARTPush *)push proxyOptions:(ARTWrapperSDKProxyOptions *)proxyOptions {
    if (self = [super init]) {
        _underlyingPush = push;
        _proxyOptions = proxyOptions;
        _admin = [[ARTWrapperSDKProxyPushAdmin alloc] initWithPushAdmin:push.admin
                                                           proxyOptions:proxyOptions];
    }

    return self;
}

#if TARGET_OS_IOS

- (void)activate {
    [self.underlyingPush activate];
}

- (void)deactivate {
    [self.underlyingPush deactivate];
}

+ (void)didFailToRegisterForLocationNotificationsWithError:(nonnull NSError *)error realtime:(nonnull ARTRealtime *)realtime {
    [ARTPush didFailToRegisterForLocationNotificationsWithError:error realtime:realtime];
}

+ (void)didFailToRegisterForLocationNotificationsWithError:(nonnull NSError *)error rest:(nonnull ARTRest *)rest {
    [ARTPush didFailToRegisterForLocationNotificationsWithError:error rest:rest];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error realtime:(nonnull ARTRealtime *)realtime {
    [ARTPush didFailToRegisterForRemoteNotificationsWithError:error realtime:realtime];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(nonnull NSError *)error rest:(nonnull ARTRest *)rest {
    [ARTPush didFailToRegisterForRemoteNotificationsWithError:error rest:rest];
}

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(nonnull NSData *)deviceToken realtime:(nonnull ARTRealtime *)realtime {
    [ARTPush didRegisterForLocationNotificationsWithDeviceToken:deviceToken realtime:realtime];
}

+ (void)didRegisterForLocationNotificationsWithDeviceToken:(nonnull NSData *)deviceToken rest:(nonnull ARTRest *)rest {
    [ARTPush didRegisterForLocationNotificationsWithDeviceToken:deviceToken rest:rest];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken realtime:(nonnull ARTRealtime *)realtime {
    [ARTPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken realtime:realtime];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken rest:(nonnull ARTRest *)rest {
    [ARTPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken rest:rest];
}

#endif

@end
