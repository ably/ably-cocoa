#import <Foundation/Foundation.h>
#import "ARTDeviceStorage.h"

@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@interface ARTLocalDeviceStorage : NSObject<ARTDeviceStorage>

- (instancetype)initWithLogger:(ARTInternalLog *)logger;

+ (instancetype)newWithLogger:(ARTInternalLog *)logger;

@end

NS_ASSUME_NONNULL_END
