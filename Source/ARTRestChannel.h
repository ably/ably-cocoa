#import <Foundation/Foundation.h>

#import <Ably/ARTChannel.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTRestPresence;
@class ARTPushChannel;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTRestChannel` is implemented.
 */
@protocol ARTRestChannelProtocol <ARTChannelProtocol>

/// :nodoc: TODO: docstring
@property (readonly, nullable) ARTChannelOptions *options;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTMessage` objects for the channel. If the channel is configured to persist messages, then messages can be retrieved from history for up to 72 hours in the past. If not, messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param query An `ARTDataQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTMessage` objects.
 * @param errorPtr A reference to the `NSError` object where an error information will be saved in case of failure.
 *
 * @return In case of failure returns false and the error information can be retrived via the `error` parameter.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedMessagesCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Retrieves a `ARTChannelDetails` object for the channel, which includes status and occupancy metrics.
 *
 * @param callback A callback for receiving the `ARTChannelDetails` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)status:(ARTChannelDetailsCallback)callback;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Sets the `ARTChannelOptions` for the channel.
 *
 * @param options A `ARTChannelOptions` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)setOptions:(ARTChannelOptions *_Nullable)options;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Enables messages to be published and historic messages to be retrieved for a channel.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTRestChannel : NSObject <ARTRestChannelProtocol>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTRestPresence` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTRestPresence *presence;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTPushChannel` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly) ARTPushChannel *push;

@end

NS_ASSUME_NONNULL_END
