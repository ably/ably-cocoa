#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage : NSObject<NSCopying>

/// A unique id for this message
@property (nullable, strong, nonatomic) NSString *id;

/// The timestamp for this message
@property (strong, nonatomic, nullable) NSDate *timestamp;

/**
 * BEGIN CANONICAL DOCSTRING
 * The client ID of the publisher of this message.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * The id of the publisher of this message
 * END LEGACY DOCSTRING
 */
@property (strong, nonatomic, nullable) NSString *clientId;

/**
 * BEGIN CANONICAL DOCSTRING
 * The connection ID of the publisher of this message.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * The connection id of the publisher of this message
 * END LEGACY DOCSTRING
 */
@property (strong, nonatomic) NSString *connectionId;

/**
 * BEGIN CANONICAL DOCSTRING
 * This is typically empty, as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute contains the remaining transformations not applied to the `data` payload.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * Any transformation applied to the data for this message
 * END LEGACY DOCSTRING
 */
@property (strong, nonatomic, nullable) NSString *encoding;

/**
 * BEGIN CANONICAL DOCSTRING
 * The message payload, if provided.
 * END CANONICAL DOCSTRING
 */
@property (strong, nonatomic, nullable) id data;

@property (strong, nullable, nonatomic) id<ARTJsonCompatible> extras;

- (NSString *)description;

- (NSInteger)messageSize;

@end

NS_ASSUME_NONNULL_END
