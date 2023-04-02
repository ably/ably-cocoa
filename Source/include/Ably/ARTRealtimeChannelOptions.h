#import <Foundation/Foundation.h>

#import <Ably/ARTChannelOptions.h>

/**
 * Describes the possible flags used to configure client capabilities, using `ARTChannelOptions`.
 */
typedef NS_OPTIONS(NSUInteger, ARTChannelMode) {
    /**
         * The client can enter the presence set.
         */
    ARTChannelModePresence = 1 << 16,
    /**
         * The client can publish messages.
         */
    ARTChannelModePublish = 1 << 17,
    /**
         * The client can subscribe to messages.
         */
    ARTChannelModeSubscribe = 1 << 18,
    /**
         * The client can receive presence messages.
         */
    ARTChannelModePresenceSubscribe = 1 << 19
};

NS_ASSUME_NONNULL_BEGIN

/**
 * Passes additional properties to an `ARTRealtimeChannel` object, such as encryption, an `ARTChannelMode` and channel parameters.
 */
@interface ARTRealtimeChannelOptions : ARTChannelOptions

/**
 * [Channel Parameters](https://ably.com/docs/realtime/channels/channel-parameters/overview) that configure the behavior of the channel.
 */
@property (nonatomic, strong, nullable) NSStringDictionary *params;

/**
 * An array of `ARTChannelMode` objects.
 */
@property (nonatomic, assign) ARTChannelMode modes;

@end

NS_ASSUME_NONNULL_END
