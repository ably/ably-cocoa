@import Foundation;

@protocol ARTDeviceStorage;
@class ARTLocalDevice;
@class ARTInternalLog;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTLocalDeviceFetcher

// clientID may be ignored if local device already exists
// can safely be called from any thread
- (ARTLocalDevice *)fetchLocalDeviceWithClientID:(NSString *)clientID
                                         storage:(id<ARTDeviceStorage>)storage
                                          logger:(nullable ARTInternalLog *)logger;

@end

@interface ARTDefaultLocalDeviceFetcher: NSObject <ARTLocalDeviceFetcher>

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, class, readonly) ARTDefaultLocalDeviceFetcher *sharedInstance;

// This is only intended to be called from test code.
- (void)resetDevice;

@end

NS_ASSUME_NONNULL_END
