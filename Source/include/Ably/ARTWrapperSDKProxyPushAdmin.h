#import <Foundation/Foundation.h>
#import <Ably/ARTPushAdmin.h>

@class ARTPushDeviceRegistrations;
@class ARTPushChannelSubscriptions;

NS_ASSUME_NONNULL_BEGIN

/**
 * An object which wraps an instance of `ARTPushAdmin` and provides a similar API. It allows Ably-authored wrapper SDKs to send analytics information so that Ably can track the usage of the wrapper SDK.
 *
 * - Important: This class should only be used by Ably-authored SDKs.
 */
NS_SWIFT_SENDABLE
@interface ARTWrapperSDKProxyPushAdmin : NSObject <ARTPushAdminProtocol>

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) ARTPushDeviceRegistrations *deviceRegistrations;
@property (nonatomic, readonly) ARTPushChannelSubscriptions *channelSubscriptions;

@end

NS_ASSUME_NONNULL_END
