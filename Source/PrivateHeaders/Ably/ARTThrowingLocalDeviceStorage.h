#import <Foundation/Foundation.h>
#import "ARTDeviceStorage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An `ARTDeviceStorage` whose every method raises
 `NSInternalInconsistencyException`. Used as the storage of an
 `ARTRestInternal` when `ARTTestClientOptions.disableLocalDevice` is set,
 so that any code path which reaches storage on a client configured to
 have no local device surfaces a clear failure instead of silently
 persisting (or reading stale) state.
 */
@interface ARTThrowingLocalDeviceStorage : NSObject<ARTDeviceStorage>
@end

NS_ASSUME_NONNULL_END
