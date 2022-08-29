#import <Foundation/Foundation.h>

#import <Ably/ARTChannelOptions.h>

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Describes the possible flags used to configure client capabilities, using `ARTChannelOptions`.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * ARTChannelMode bitmask matching the ARTProtocolMessageFlag.
 * END LEGACY DOCSTRING
 */
typedef NS_OPTIONS(NSUInteger, ARTChannelMode) {
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The client can enter the presence set.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTChannelModePresence = 1 << 16,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The client can publish messages.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTChannelModePublish = 1 << 17,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The client can subscribe to messages.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTChannelModeSubscribe = 1 << 18,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * The client can receive presence messages.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTChannelModePresenceSubscribe = 1 << 19
};

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannelOptions : ARTChannelOptions

@property (nonatomic, strong, nullable) NSStringDictionary *params;
@property (nonatomic, assign) ARTChannelMode modes;

@end

NS_ASSUME_NONNULL_END
