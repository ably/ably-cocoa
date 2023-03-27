#import <Foundation/Foundation.h>
#import <Ably/ARTDeviceStorage.h>

@class ARTInternalLogHandler;

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@interface ARTLocalDeviceStorage : NSObject<ARTDeviceStorage>

- (instancetype)initWithLogger:(ARTInternalLogHandler *)logger;

+ (instancetype)newWithLogger:(ARTInternalLogHandler *)logger;

@end

NS_ASSUME_NONNULL_END
