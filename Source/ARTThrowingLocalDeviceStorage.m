#import "ARTThrowingLocalDeviceStorage.h"

@implementation ARTThrowingLocalDeviceStorage

- (nullable id)objectForKey:(NSString *)key {
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ invoked with key %@ on a client configured with disableLocalDevice", NSStringFromSelector(_cmd), key];
    return nil;
}

- (void)setObject:(nullable id)value forKey:(NSString *)key {
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ invoked with key %@ on a client configured with disableLocalDevice", NSStringFromSelector(_cmd), key];
}

- (nullable NSString *)secretForDevice:(ARTDeviceId *)deviceId {
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ invoked for device %@ on a client configured with disableLocalDevice", NSStringFromSelector(_cmd), deviceId];
    return nil;
}

- (void)setSecret:(nullable NSString *)value forDevice:(ARTDeviceId *)deviceId {
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ invoked for device %@ on a client configured with disableLocalDevice", NSStringFromSelector(_cmd), deviceId];
}

@end
