#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A base interface for an `ARTMessage` and an `ARTPresenceMessage` objects.
 */
@interface ARTBaseMessage : NSObject<NSCopying>

/**
 * A Unique ID assigned by Ably to this message.
 */
@property (nullable, strong, nonatomic) NSString *id;

/**
 * Timestamp of when the message was received by Ably, as a `NSDate` object.
 */
@property (strong, nonatomic, nullable) NSDate *timestamp;

/**
 * The client ID of the publisher of this message.
 */
@property (strong, nonatomic, nullable) NSString *clientId;

/**
 * The connection ID of the publisher of this message.
 */
@property (strong, nonatomic) NSString *connectionId;

/**
 * This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
 */
@property (strong, nonatomic, nullable) NSString *encoding;

/**
 * The message payload, if provided.
 */
@property (strong, nonatomic, nullable) id data;

/**
 * A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 */
@property (strong, nullable, nonatomic) id<ARTJsonCompatible> extras;

/// :nodoc:
- (NSString *)description;

/// :nodoc:
- (NSInteger)messageSize;

@end

NS_ASSUME_NONNULL_END
