#import "ARTLog.h"
#import "ARTLocalDevice+Private.h"
#import "ARTUserDefaultsLocalDeviceStorage.h"

@implementation ARTUserDefaultsLocalDeviceStorage

- (nullable id)objectForKey:(NSString *)key {
    return [NSUserDefaults.standardUserDefaults objectForKey:key];
}

- (void)setObject:(nullable id)value forKey:(NSString *)key {
    [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
}

- (NSString *)secretForDevice:(ARTDeviceId *)deviceId {
    return [self objectForKey:deviceId];
}

- (void)setSecret:(NSString *)value forDevice:(ARTDeviceId *)deviceId {
    [self setObject:value forKey:deviceId];
}

@end
