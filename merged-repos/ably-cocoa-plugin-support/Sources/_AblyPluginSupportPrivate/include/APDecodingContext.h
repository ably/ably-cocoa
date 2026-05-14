@import Foundation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecodingContextProtocol)
NS_SWIFT_SENDABLE
/// Contains contextual information that may be needed when decoding an object contained within a `ProtocolMessage`.
@protocol APDecodingContextProtocol

/// The `id` of the `ProtocolMessage` that contains the object that is being decoded.
@property (nonatomic, readonly, nullable) NSString *parentID;

/// The `connectionId` of the `ProtocolMessage` that contains the object that is being decoded.
@property (nonatomic, readonly, nullable) NSString *parentConnectionID;

/// The `timestamp` of the `ProtocolMessage` that contains the object that is being decoded.
@property (nonatomic, readonly, nullable) NSDate *parentTimestamp;

/// The index, inside the array in the `ProtocolMessage` that contains the object that is being decoded, of the object that is being decoded.
@property (nonatomic, readonly) NSInteger indexInParent;

@end

NS_ASSUME_NONNULL_END
