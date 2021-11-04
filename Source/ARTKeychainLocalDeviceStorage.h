#import <Ably/ARTUserDefaultsLocalDeviceStorage.h>

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTKeychainLocalDeviceStorage : ARTUserDefaultsLocalDeviceStorage

- (instancetype)initWithLogger:(ARTLog *)logger;

+ (instancetype)newWithLogger:(ARTLog *)logger;

@end

NS_ASSUME_NONNULL_END
