#import <Foundation/Foundation.h>

#import <Ably/ARTChannelOptions.h>

/**
 * BEGIN CANONICAL DOCSTRING
 * Describes the possible flags used to configure client capabilities, using `ARTChannelOptions`.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * ARTChannelMode bitmask matching the ARTProtocolMessageFlag.
 * END LEGACY DOCSTRING
 */
typedef NS_OPTIONS(NSUInteger, ARTChannelMode) {
    /**
     * BEGIN CANONICAL DOCSTRING
     * The client can enter the presence set.
     * END CANONICAL DOCSTRING
     */
    ARTChannelModePresence = 1 << 16,
    /**
     * BEGIN CANONICAL DOCSTRING
     * The client can publish messages.
     * END CANONICAL DOCSTRING
     */
    ARTChannelModePublish = 1 << 17,
    /**
     * BEGIN CANONICAL DOCSTRING
     * The client can subscribe to messages.
     * END CANONICAL DOCSTRING
     */
    ARTChannelModeSubscribe = 1 << 18,
    /**
     * BEGIN CANONICAL DOCSTRING
     * The client can receive presence messages.
     * END CANONICAL DOCSTRING
     */
    ARTChannelModePresenceSubscribe = 1 << 19
};

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannelOptions : ARTChannelOptions

@property (nonatomic, strong, nullable) NSStringDictionary *params;
@property (nonatomic, assign) ARTChannelMode modes;

@end

NS_ASSUME_NONNULL_END
