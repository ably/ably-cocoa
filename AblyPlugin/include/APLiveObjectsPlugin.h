#import <Foundation/Foundation.h>

@class ARTRealtimeChannel;
@protocol APLiveObjectsInternalPluginProtocol;

NS_ASSUME_NONNULL_BEGIN

/// The entrypoint by which ably-cocoa accesses the functionality provided by the LiveObjects plugin.
///
/// The value that the user provides for the `ARTPluginNameLiveObjects` key in the  `-[ARTClientOptions plugins]` client option must _informally_ conform to this protocol; that is, it must implement its methods but not declare itself as conforming to the protocol. (We use informal conformance so that the LiveObjects plugin does not need to expose its usage of the `ARTPlugin` library to the user.)
NS_SWIFT_NAME(LiveObjectsPluginProtocol)
NS_SWIFT_SENDABLE
@protocol APLiveObjectsPluginProtocol <NSObject>

/// Provides ably-cocoa with an implementation of `APLiveObjectsInternalPluginProtocol`.
+ (id<APLiveObjectsInternalPluginProtocol>)internalPlugin;

@end

/// The interface that ably-cocoa uses to access the functionality provided by the LiveObjects plugin.
///
/// This protocol can be more complex than `APLiveObjectsPluginProtocol`, because, since its implementation will be internal to the LiveObjects plugin library, then, unlike the informal conformance that we have to use for `APLiveObjectsPluginProtocol`, the implementation can declare itself as conforming to this protocol and will receive compiler checking that it does indeed conform.
NS_SWIFT_NAME(LiveObjectsInternalPluginProtocol)
NS_SWIFT_SENDABLE
@protocol APLiveObjectsInternalPluginProtocol <NSObject>

/// ably-cocoa will call this method when initializing an `ARTRealtimeChannel` instance.
///
/// The plugin can use this as an opportunity to perform any initial setup of LiveObjects functionality for this channel.
- (void)prepareChannel:(ARTRealtimeChannel *)channel;

@end

NS_ASSUME_NONNULL_END
