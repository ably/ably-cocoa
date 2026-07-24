@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// The serial for a single published message.
NS_SWIFT_SENDABLE
NS_SWIFT_NAME(PublishResultSerialProtocol)
@protocol APPublishResultSerialProtocol <NSObject>

/// The message serial of the published message, or `nil` if the message was discarded due to a configured conflation rule.
@property (nullable, nonatomic, readonly) NSString *value;

@end

/// Contains the result of a publish operation.
NS_SWIFT_SENDABLE
NS_SWIFT_NAME(PublishResultProtocol)
@protocol APPublishResultProtocol <NSObject>

/// An array of serials corresponding 1:1 to the messages that were published.
@property (nonatomic, readonly) NSArray<id<APPublishResultSerialProtocol>> *serials;

@end

NS_ASSUME_NONNULL_END
