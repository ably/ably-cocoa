@import Foundation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ConnectionDetailsProtocol)
NS_SWIFT_SENDABLE
/// The contents of a `CONNECTED` `ProtocolMessage`'s `connectionDetails`.
@protocol APConnectionDetailsProtocol

/// Wraps an `NSTimeInterval` containing the `objectsGCGracePeriod`, if any, in seconds.
@property (nonatomic, readonly, nullable) NSNumber *objectsGCGracePeriod;

/// The maximum message size allowed by the Ably account this connection is using (CD2c). A value of
/// `0` indicates that the server did not send a limit, in which case the plugin should fall back to
/// the Ably default. Used by the RTO15d publish-size gate (see ably-java `Helpers.kt:168`,
/// `connectionManager.maxMessageSize`).
@property (nonatomic, readonly) NSInteger maxMessageSize;

/// The site code of the server that the client is connected to (CD2j).
///
/// May be absent if the server does not provide it.
@property (nonatomic, readonly, nullable) NSString *siteCode;

@end

NS_ASSUME_NONNULL_END
