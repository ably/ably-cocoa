@import Foundation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ConnectionDetailsProtocol)
NS_SWIFT_SENDABLE
/// The contents of a `CONNECTED` `ProtocolMessage`'s `connectionDetails`.
@protocol APConnectionDetailsProtocol

/// Wraps an `NSTimeInterval` containing the `objectsGCGracePeriod`, if any, in seconds.
@property (nonatomic, readonly, nullable) NSNumber *objectsGCGracePeriod;

@end

NS_ASSUME_NONNULL_END
