#import <Foundation/Foundation.h>
#import <Ably/ARTDeviceStorage.h>

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

// TODO we assume there's only one instance of this from a synchronisation point of view, document that
// also we make no assumptions about the thread this might be used from

@interface ARTLocalDeviceStorage : NSObject<ARTDeviceStorage>

- (instancetype)initWithLogger:(ARTLog *)logger;

+ (instancetype)newWithLogger:(ARTLog *)logger;

@end

NS_ASSUME_NONNULL_END
