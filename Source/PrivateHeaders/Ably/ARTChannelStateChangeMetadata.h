@import Foundation;
#import <Ably/ARTTypes.h>

@class ARTErrorInfo;
@class ARTRetryAttempt;

NS_ASSUME_NONNULL_BEGIN

/**
 Provides metadata for a request to perform an operation that may cause an `ARTRealtimeChannelInternal` instance to emit a connection state change.

 `ARTRealtimeChannelInternal` will incorporate some of this data into the `ARTChannelStateChange` object that it emits as a result of the connection state change.
 */
NS_SWIFT_NAME(ChannelStateChangeMetadata)
@interface ARTChannelStateChangeMetadata: NSObject

/**
 A state that some operations will use when failing pending presence operations.
 */
@property (nonatomic, readonly) ARTState state;

/**
 Information about the error that triggered this state change, if any.
 */
@property (nullable, nonatomic, readonly) ARTErrorInfo *errorInfo;

/**
 Whether the `ARTRealtimeChannelInternal` instance should update its `errorReason` property.
 */
@property (nonatomic, readonly) BOOL storeErrorInfo;

@property (nullable, nonatomic, readonly) ARTRetryAttempt *retryAttempt;

- (instancetype)init NS_UNAVAILABLE;

/**
 Creates an `ARTChannelStateChangeMetadata` instance whose `errorInfo` is `nil`, and whose `storeErrorInfo` is `NO`.
 */
- (instancetype)initWithState:(ARTState)state;

/**
 Creates an `ARTChannelStateChangeMetadata` instance with the given `errorInfo`, whose `storeErrorInfo` is `YES`.
 */
- (instancetype)initWithState:(ARTState)state
                    errorInfo:(nullable ARTErrorInfo *)errorInfo;

- (instancetype)initWithState:(ARTState)state
                    errorInfo:(nullable ARTErrorInfo *)errorInfo
               storeErrorInfo:(BOOL)storeErrorInfo;

- (instancetype)initWithState:(ARTState)state
                    errorInfo:(nullable ARTErrorInfo *)errorInfo
               storeErrorInfo:(BOOL)storeErrorInfo
                 retryAttempt:(nullable ARTRetryAttempt *)retryAttempt NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
