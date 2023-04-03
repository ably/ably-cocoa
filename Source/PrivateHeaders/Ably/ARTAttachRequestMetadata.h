@import Foundation;

@class ARTErrorInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 Provides metadata for a request to perform an operation that may ultimately call `ARTChannelRealtimeInternal`’s `internalAttach:callback:` method.
 */
NS_SWIFT_NAME(AttachRequestMetadata)
@interface ARTAttachRequestMetadata: NSObject

/**
 Information about the error that triggered this attach request, if any.
 */
@property (nullable, nonatomic, readonly) ARTErrorInfo *reason;

/**
 The value to set for the `ATTACH` `ProtocolMessage`’s `channelSerial` property.
 */
@property (nullable, nonatomic, readonly) NSString *channelSerial;

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates an `ARTAttachRequestMetadata` instance with the given `reason`, whose `channelSerial` is `nil`.
 */
- (instancetype)initWithReason:(nullable ARTErrorInfo *)reason;

- (instancetype)initWithReason:(nullable ARTErrorInfo *)reason channelSerial:(nullable NSString *)channelSerial NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
