#import <Ably/ARTUserDefaultsLocalDeviceStorage.h>

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

/**
 Keychain storage for the device secret. It uses your device's keychain as a storage mechanism.
 See ``ARTClientOptions/storage`` for further details.
 */
@interface ARTKeychainLocalDeviceStorage : ARTUserDefaultsLocalDeviceStorage

- (instancetype)initWithLogger:(ARTLog *)logger;

+ (instancetype)newWithLogger:(ARTLog *)logger;

@end

NS_ASSUME_NONNULL_END
