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

- (void)performBatchUpdate:(NS_NOESCAPE void (^)(id<ARTDeviceStorage>))block {
    [NSException raise:NSInternalInconsistencyException
                format:@"%@ invoked on a client configured with disableLocalDevice", NSStringFromSelector(_cmd)];
}

@end
