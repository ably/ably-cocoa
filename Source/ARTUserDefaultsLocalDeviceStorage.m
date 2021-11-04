#import "ARTLog.h"
#import "ARTLocalDevice+Private.h"
#import "ARTUserDefaultsLocalDeviceStorage.h"
#import "ARTKeychainLocalDeviceStorage.h"

@implementation ARTUserDefaultsLocalDeviceStorage

- (nullable id)objectForKey:(NSString *)key {
    return [NSUserDefaults.standardUserDefaults objectForKey:key];
}

- (void)setObject:(nullable id)value forKey:(NSString *)key {
    [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
}

- (NSString *)secretForDevice:(ARTDeviceId *)deviceId {
    NSString *value = [self objectForKey:deviceId];
    if (value == nil) { // probably a migration from a previous keychain (as a default) storage
        value = [ARTKeychainLocalDeviceStorage keychainGetPasswordForService:ARTDeviceSecretKey account:deviceId error:nil];
        if (value != nil) {
            [self setSecret:value forDevice:deviceId];
        }
    }
    return value;
}

- (void)setSecret:(NSString *)value forDevice:(ARTDeviceId *)deviceId {
    [self setObject:value forKey:deviceId];
}

@end
