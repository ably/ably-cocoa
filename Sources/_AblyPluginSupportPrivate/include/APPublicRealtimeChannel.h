@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// A marker protocol that this library uses to represent an instance of ably-cocoa's `ARTRealtimeChannel`.
///
/// Both ably-cocoa and it plugins can treat this type interchangeably with `ARTRealtimeChannel`; that is, they can assume that the only class that conforms to this protocol is `ARTRealtimeChannel`, casting between the two as they wish.
///
/// The word "public" in this type's name indicates that it corresponds to a type that is public in ably-cocoa.
///
/// - Note: `ARTRealtimeChannel`'s runtime conformance to this protocol is implemented by ably-cocoa (but it is not able to declare this conformance publicly).
NS_SWIFT_NAME(PublicRealtimeChannel)
@protocol APPublicRealtimeChannel <NSObject>
@end

NS_ASSUME_NONNULL_END
