#import <Foundation/Foundation.h>
#import <Ably/ARTPush.h>

@class ARTWrapperSDKProxyPushAdmin;

NS_ASSUME_NONNULL_BEGIN

/**
 * An object which wraps an instance of `ARTPush` and provides a similar API. It allows Ably-authored wrapper SDKs to send analytics information so that Ably can track the usage of the wrapper SDK.
 *
 * - Important: This class should only be used by Ably-authored SDKs.
 */
NS_SWIFT_SENDABLE
@interface ARTWrapperSDKProxyPush : NSObject <ARTPushProtocol>

- (instancetype)init NS_UNAVAILABLE;

@property (readonly) ARTWrapperSDKProxyPushAdmin *admin;

@end

NS_ASSUME_NONNULL_END
