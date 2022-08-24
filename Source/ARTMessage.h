#import <Foundation/Foundation.h>

#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTChannelOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains an individual message that is sent to, or received from, Ably.
 * END CANONICAL DOCSTRING
 */
@interface ARTMessage : ARTBaseMessage

/// The event name, if available
@property (nullable, readwrite, strong, nonatomic) NSString *name;

/**
 * BEGIN CANONICAL DOCSTRING
 * Construct a `Message` object with an event name and payload.
 *
 * @param name The event name.
 * @param data The message payload.
 * END CANONICAL DOCSTRING
 */
- (instancetype)initWithName:(nullable NSString *)name data:(id)data;

/**
 * BEGIN CANONICAL DOCSTRING
 * Construct a `Message` object with an event name, payload, and a unique client ID.
 *
 * @param name The event name.
 * @param data The message payload.
 * @param clientId The client ID of the publisher of this message.
 * END CANONICAL DOCSTRING
 */
- (instancetype)initWithName:(nullable NSString *)name data:(id)data clientId:(NSString *)clientId;

@end

@interface ARTMessage (Decoding)

/**
 * BEGIN CANONICAL DOCSTRING
 * A static factory method to create a `Message` object from a deserialized Message-like object encoded using Ably's wire protocol.
 *
 * @param jsonObject A `Message`-like deserialized object.
 * @param options A `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
 *
 * @return A `Message` object.
 * END CANONICAL DOCSTRING
 */
+ (nullable instancetype)fromEncoded:(NSDictionary *)jsonObject
                      channelOptions:(ARTChannelOptions *)options
                               error:(NSError *_Nullable *_Nullable)error;

/**
 * BEGIN CANONICAL DOCSTRING
 * A static factory method to create an array of `Message` objects from an array of deserialized Message-like object encoded using Ably's wire protocol.
 *
 * @param jsonArray An array of `Message`-like deserialized objects.
 * @param options A `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
 *
 * @return An array of `ARTMessage` objects.
 * END CANONICAL DOCSTRING
 */
+ (nullable NSArray<ARTMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray
                                      channelOptions:(ARTChannelOptions *)options
                                               error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
