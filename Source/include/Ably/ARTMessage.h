#import <Foundation/Foundation.h>

#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTChannelOptions.h>

/**
 * The namespace containing the different types of message actions.
 */
NS_SWIFT_SENDABLE
typedef NS_ENUM(NSUInteger, ARTMessageAction) {
    /**
     * Message action for a newly created message.
     */
    ARTMessageActionCreate,
    /**
     * Message action for an updated message.
     */
    ARTMessageActionUpdate,
    /**
     * Message action for a deleted message.
     */
    ARTMessageActionDelete,
    /**
     * Message action for a meta-message that contains channel occupancy information.
     */
    ARTMessageActionMetaOccupancy,
    /**
     * Message action for a message containing the latest rolled-up summary of
     * annotations that have been made to this message.
     */
    ARTMessageActionMessageSummary,
};

NS_ASSUME_NONNULL_BEGIN

@class ARTMessageOperation;

/**
 * Contains an individual message that is sent to, or received from, Ably.
 */
@interface ARTMessage : ARTBaseMessage

/// The event name, if available
@property (nullable, readwrite, nonatomic) NSString *name;

/// The action type of the message, one of the `ARTMessageAction` enum values.
@property (readwrite, nonatomic) ARTMessageAction action;

/// The version of the message, lexicographically-comparable with other versions (that share the same serial).
/// Will differ from the serial only if the message has been updated or deleted.
@property (nullable, readwrite, nonatomic) NSString *version;

/// This message's unique serial (an identifier that will be the same in all future updates of this message).
@property (nullable, readwrite, nonatomic) NSString *serial;

/// The serial of the operation that updated this message.
@property (nullable, readwrite, nonatomic) NSString *updateSerial;

/// The timestamp of the very first version of a given message.
@property (nonatomic, nullable) NSDate *createdAt;

/// The timestamp of the most recent update to this message.
@property (nonatomic, nullable) NSDate *updatedAt;

/// An opaque string that uniquely identifies some referenced message.
@property (nonatomic, nullable) NSString *refSerial;

/// An opaque string that identifies the type of this reference.
@property (nonatomic, nullable) NSString *refType;

/// An object containing some optional values for the operation performed.
@property (nonatomic, strong, nullable) ARTMessageOperation *operation;

/**
 * Construct an `ARTMessage` object with an event name and payload.
 *
 * @param name The event name.
 * @param data The message payload.
 */
- (instancetype)initWithName:(nullable NSString *)name data:(id)data;

/**
 * Construct an `ARTMessage` object with an event name, payload, and a unique client ID.
 *
 * @param name The event name.
 * @param data The message payload.
 * @param clientId The client ID of the publisher of this message.
 */
- (instancetype)initWithName:(nullable NSString *)name data:(id)data clientId:(NSString *)clientId;

@end

@interface ARTMessage (Decoding)

/**
 * A static factory method to create an `ARTMessage` object from a deserialized Message-like object encoded using Ably's wire protocol.
 *
 * @param jsonObject A `Message`-like deserialized object.
 * @param options An `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
 *
 * @return An `ARTMessage` object.
 */
+ (nullable instancetype)fromEncoded:(NSDictionary *)jsonObject
                      channelOptions:(ARTChannelOptions *)options
                               error:(NSError *_Nullable *_Nullable)error;

/**
 * A static factory method to create an array of `ARTMessage` objects from an array of deserialized Message-like object encoded using Ably's wire protocol.
 *
 * @param jsonArray An array of `Message`-like deserialized objects.
 * @param options An `ARTChannelOptions` object. If you have an encrypted channel, use this to allow the library to decrypt the data.
 *
 * @return An array of `ARTMessage` objects.
 */
+ (nullable NSArray<ARTMessage *> *)fromEncodedArray:(NSArray<NSDictionary *> *)jsonArray
                                      channelOptions:(ARTChannelOptions *)options
                                               error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END

