@import Foundation;

@class ARTErrorInfo;
@class ARTRetryAttempt;

NS_ASSUME_NONNULL_BEGIN

/**
 Provides parameters for a request to perform an operation that may ultimately call `ARTChannelRealtimeInternal`’s `internalAttach:callback:` method.
 */
NS_SWIFT_NAME(AttachRequestParams)
@interface ARTAttachRequestParams: NSObject

/**
 Information about the error that triggered this attach request, if any.
 */
@property (nullable, nonatomic, readonly) ARTErrorInfo *reason;

/**
 The value to set for the `ATTACH` `ProtocolMessage`’s `channelSerial` property.
 */
@property (nullable, nonatomic, readonly) NSString *channelSerial;

@property (nullable, nonatomic, readonly) ARTRetryAttempt *retryAttempt;

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates an `ARTAttachRequestParams` instance with the given `reason`, whose `channelSerial` is `nil`.
 */
- (instancetype)initWithReason:(nullable ARTErrorInfo *)reason;

/**
 Creates an `ARTAttachRequest` instance with the given `reason` and `channelSerial`, whose `retryAttempt` is `nil`.
 */
- (instancetype)initWithReason:(nullable ARTErrorInfo *)reason channelSerial:(nullable NSString *)channelSerial;

- (instancetype)initWithReason:(nullable ARTErrorInfo *)reason channelSerial:(nullable NSString *)channelSerial retryAttempt:(nullable ARTRetryAttempt *)retryAttempt NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
