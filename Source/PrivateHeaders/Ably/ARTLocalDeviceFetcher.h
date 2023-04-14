@import Foundation;

@protocol ARTDeviceStorage;
@class ARTLocalDevice;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

/**
`ARTLocalDeviceFetcher` is responsible for fetching an instance of `ARTLocalDevice`.
 */
NS_SWIFT_NAME(LocalDeviceFetcher)
@protocol ARTLocalDeviceFetcher

/**
 Fetches an `ARTLocalDevice` instance. The receiver may ignore the arguments (e.g. if it has already instantiated an `ARTLocalDevice` instance, it may instead return that instance).

 This method can safely be called from any thread.
 */
- (ARTLocalDevice *)fetchLocalDeviceWithClientID:(NSString *)clientID
                                         storage:(id<ARTDeviceStorage>)storage
                                          logger:(nullable ARTInternalLog *)logger;

@end

/**
 The implementation of `ARTLocalDeviceFetcher` that should be used in non-test code. Its `sharedInstance` class property manages the `ARTLocalDevice` instance shared by all `ARTRest` instances.
 */
NS_SWIFT_NAME(DefaultLocalDeviceFetcher)
@interface ARTDefaultLocalDeviceFetcher: NSObject <ARTLocalDeviceFetcher>

/**
 Use `ARTDefaultLocalDeviceFetcher.sharedInstance` instead of `init`.
 */
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, class, readonly) ARTDefaultLocalDeviceFetcher *sharedInstance;

@end

NS_ASSUME_NONNULL_END
