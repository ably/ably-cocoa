#import <Ably/ARTDeviceStorage.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Default storage for the device secret. It uses ``NSUserDefaults`` as a storage mechanism. If you want to store your device secret securely, consider to use your own implementation of the ``ARTDeviceStorage`` protocol or use our `ARTKeychainLocalDeviceStorage` implementation.
 See ``ARTClientOptions/storage`` for further details.
 */
@interface ARTDefaultLocalDeviceStorage : NSObject<ARTDeviceStorage>
@end

NS_ASSUME_NONNULL_END
