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

/**
 Class methods for manipulating securely stored data in a keychain
 */
@interface ARTKeychainLocalDeviceStorage (Sec)

/**
 Gets password from a keychain for a particular service name and account
 */
+ (nullable NSString *)keychainGetPasswordForService:(NSString *)serviceName
                                             account:(NSString *)account
                                               error:(NSError *__autoreleasing *)error;
/**
 Deletes password from a keychain for a particular service name and account
 */
+ (BOOL)keychainDeletePasswordForService:(NSString *)serviceName
                                 account:(NSString *)account
                                   error:(NSError *__autoreleasing *)error;
/**
 Stores password in a keychain for a particular service name and account
 */
+ (BOOL)keychainSetPassword:(NSString *)password
                 forService:(NSString *)serviceName
                    account:(NSString *)account
                      error:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
