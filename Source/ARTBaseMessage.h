#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A base interface for an `ARTMessage` and an `ARTPresenceMessage` objects.
 */
@interface ARTBaseMessage : NSObject<NSCopying>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A Unique ID assigned by Ably to this message.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nullable, strong, nonatomic) NSString *id;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Timestamp of when the message was received by Ably, as a `NSDate` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic, nullable) NSDate *timestamp;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The client ID of the publisher of this message.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic, nullable) NSString *clientId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The connection ID of the publisher of this message.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic) NSString *connectionId;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic, nullable) NSString *encoding;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The message payload, if provided.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nonatomic, nullable) id data;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (strong, nullable, nonatomic) id<ARTJsonCompatible> extras;

- (NSString *)description;

- (NSInteger)messageSize;

@end

NS_ASSUME_NONNULL_END
