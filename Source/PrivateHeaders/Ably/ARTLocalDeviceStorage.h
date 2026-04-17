#import <Foundation/Foundation.h>
#import "ARTDeviceStorage.h"

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTLocalDeviceStorage : NSObject<ARTDeviceStorage>

- (instancetype)initWithLogger:(ARTInternalLog *)logger logValues:(BOOL)logValues;

+ (instancetype)newWithLogger:(ARTInternalLog *)logger logValues:(BOOL)logValues;

@end

NS_ASSUME_NONNULL_END
