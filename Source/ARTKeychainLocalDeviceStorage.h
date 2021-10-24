#import <Ably/ARTDefaultLocalDeviceStorage.h>

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTKeychainLocalDeviceStorage : ARTDefaultLocalDeviceStorage

- (instancetype)initWithLogger:(ARTLog *)logger;

+ (instancetype)newWithLogger:(ARTLog *)logger;

@end

NS_ASSUME_NONNULL_END
