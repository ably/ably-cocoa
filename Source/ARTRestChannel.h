#import <Foundation/Foundation.h>

#import <Ably/ARTChannel.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTRestPresence;
@class ARTPushChannel;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTRestChannelProtocol <ARTChannelProtocol>

@property (readonly, nullable) ARTChannelOptions *options;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves a `ARTPaginatedResult` object, containing an array of historical `ARTMessage` objects for the channel. If the channel is configured to persist messages, then messages can be retrieved from history for up to 72 hours in the past. If not, messages can only be retrieved from history for up to two minutes in the past.
 *
 * @param start The time from which messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param end The time until messages are retrieved, specified as milliseconds since the Unix epoch.
 * @param direction The order for which messages are returned in. Valid values are `backwards` which orders messages from most recent to oldest, or `forwards` which orders messages from oldest to most recent. The default is `backwards`.
 * @param limit An upper limit on the number of messages returned. The default is 100, and the maximum is 1000.
 *
 * @return A `ARTPaginatedResult` object containing an array of `ARTMessage` objects.
 * END CANONICAL DOCSTRING
 */
- (BOOL)history:(nullable ARTDataQuery *)query callback:(ARTPaginatedMessagesCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

/**
 * BEGIN CANONICAL DOCSTRING
 * Retrieves a `ARTChannelDetails` object for the channel, which includes status and occupancy metrics.
 *
 * @return A `ARTChannelDetails` object.
 * END CANONICAL DOCSTRING
 */
- (void)status:(ARTChannelDetailsCallback)callback;

/**
 * BEGIN CANONICAL DOCSTRING
 * Sets the `ARTChannelOptions` for the channel.
 *
 * @param options A `ARTChannelOptions` object.
 * END CANONICAL DOCSTRING
 */
- (void)setOptions:(ARTChannelOptions *_Nullable)options;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Enables messages to be published and historic messages to be retrieved for a channel.
 * END CANONICAL DOCSTRING
 */
@interface ARTRestChannel : NSObject <ARTRestChannelProtocol>

/**
 * BEGIN CANONICAL DOCSTRING
 * A `ARTRestPresence` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTRestPresence *presence;

/**
 * BEGIN CANONICAL DOCSTRING
 * A `ARTPushChannel` object.
 * END CANONICAL DOCSTRING
 */
@property (readonly) ARTPushChannel *push;

@end

NS_ASSUME_NONNULL_END
