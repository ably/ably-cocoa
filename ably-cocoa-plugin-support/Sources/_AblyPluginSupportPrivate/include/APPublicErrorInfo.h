@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// A marker protocol that this library uses to represent an instance of ably-cocoa's `ARTErrorInfo`.
///
/// Both ably-cocoa and it plugins can treat this type interchangeably with `ARTErrorInfo`; that is, they can assume that the only class that conforms to this protocol is `ARTErrorInfo`, casting between the two as they wish.
///
/// The word "public" in this type's name indicates that it corresponds to a type that is public in ably-cocoa.
///
/// - Note: `ARTErrorInfo`'s runtime conformance to this protocol is implemented by ably-cocoa (but it is not able to declare this conformance publicly).
NS_SWIFT_NAME(PublicErrorInfo)
@protocol APPublicErrorInfo <NSObject>
@end

NS_ASSUME_NONNULL_END
