@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface ARTDefaultLocalDeviceFetcher ()

/**
 Clears the fetcher’s internal reference to the device object, such that the next time it receives a `-fetchLocalDeviceWithClientID:storage:logger:` message, it initializes a new `ARTLocalDevice` instance.

 This method should only be used in test code.
 */
- (void)resetDevice;

@end

NS_ASSUME_NONNULL_END
