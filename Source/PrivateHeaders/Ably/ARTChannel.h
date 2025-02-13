#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTChannelProtocol.h>

@class ARTRest;
@class ARTChannelOptions;
@class ARTMessage;
@class ARTBaseMessage;
@class ARTPaginatedResult<ItemType>;
@class ARTDataQuery;
@class ARTLocalDevice;

NS_ASSUME_NONNULL_BEGIN

/**
 * The base class for `ARTRestChannel` and `ARTRealtimeChannel`.
 * Ably platform service organizes the message traffic within applications into named channels. Channels are the medium through which messages are distributed; clients attach to channels to subscribe to messages, and every message published to a unique channel is broadcast by Ably to all subscribers.
 *
 * @see See `ARTChannelProtocol` for details.
 */
NS_SWIFT_SENDABLE
@interface ARTChannel : NSObject<ARTChannelProtocol>
@end

NS_ASSUME_NONNULL_END
