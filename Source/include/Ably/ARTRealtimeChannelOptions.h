#import <Foundation/Foundation.h>

#import <Ably/ARTChannelOptions.h>

/**
 * Describes the possible flags used to configure client capabilities, using `ARTChannelOptions`.
 */
typedef NS_OPTIONS(NSUInteger, ARTChannelMode) {
    /**
         * The client can enter the presence set.
         */
    ARTChannelModePresence NS_SWIFT_NAME(presence) = 1 << 16,
    /**
         * The client can publish messages.
         */
    ARTChannelModePublish NS_SWIFT_NAME(publish) = 1 << 17,
    /**
         * The client can subscribe to messages.
         */
    ARTChannelModeSubscribe NS_SWIFT_NAME(subscribe) = 1 << 18,
    /**
         * The client can receive presence messages.
         */
    ARTChannelModePresenceSubscribe NS_SWIFT_NAME(presenceSubscribe) = 1 << 19
} NS_SWIFT_NAME(ChannelMode);

NS_ASSUME_NONNULL_BEGIN

/**
 * Passes additional properties to an `ARTRealtimeChannel` object, such as encryption, an `ARTChannelMode` and channel parameters.
 */
NS_SWIFT_NAME(RealtimeChannelOptions)
@interface ARTRealtimeChannelOptions : ARTChannelOptions

/**
 * [Channel Parameters](https://ably.com/docs/realtime/channels/channel-parameters/overview) that configure the behavior of the channel.
 */
@property (nonatomic, nullable) NSStringDictionary *params;

/**
 * An array of `ARTChannelMode` objects.
 */
@property (nonatomic) ARTChannelMode modes;

@end

NS_ASSUME_NONNULL_END
