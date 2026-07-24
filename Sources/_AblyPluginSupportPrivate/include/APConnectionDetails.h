@import Foundation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ConnectionDetailsProtocol)
NS_SWIFT_SENDABLE
/// The contents of a `CONNECTED` `ProtocolMessage`'s `connectionDetails`.
@protocol APConnectionDetailsProtocol

/// Wraps an `NSTimeInterval` containing the `objectsGCGracePeriod`, if any, in seconds.
@property (nonatomic, readonly, nullable) NSNumber *objectsGCGracePeriod;

/// The site code of the server that the client is connected to (CD2j).
///
/// May be absent if the server does not provide it.
@property (nonatomic, readonly, nullable) NSString *siteCode;

@end

NS_ASSUME_NONNULL_END
