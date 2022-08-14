#import <Foundation/Foundation.h>

@class ARTRest;
@class ARTRestChannel;
@class ARTChannelOptions;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates and destroys [`RestChannel`]{@link RestChannel} and [`RealtimeChannel`]{@link RealtimeChannel} objects.
 * END CANONICAL DOCSTRING
 */
@interface ARTChannels<ChannelType> : NSObject

/**
 * BEGIN CANONICAL DOCSTRING
 * Checks if a channel has been previously retrieved using the `get()` method.
 *
 * @param name The channel name.
 *
 * @return `true` if the channel exists, otherwise `false`.
 * END CANONICAL DOCSTRING
 */
- (BOOL)exists:(NSString *)name;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates a new [`RestChannel`]{@link RestChannel} or [`RealtimeChannel`]{@link RealtimeChannel} object, or returns the existing channel object.
 *
 * @param name The channel name.
 *
 * @return A [`RestChannel`]{@link RestChannel} or [`RealtimeChannel`]{@link RealtimeChannel} object.
 * END CANONICAL DOCSTRING
 */
- (ChannelType)get:(NSString *)name;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates a new [`RestChannel`]{@link RestChannel} or [`RealtimeChannel`]{@link RealtimeChannel} object, with the specified [`ChannelOptions`]{@link ChannelOptions}, or returns the existing channel object.
 *
 * @param name The channel name.
 * @param options A [`ChannelOptions`]{@link ChannelOptions} object.
 * 
 * @return A [`RestChannel`]{@link RestChannel} or [`RealtimeChannel`]{@link RealtimeChannel} object.
 * END CANONICAL DOCSTRING
 */
- (ChannelType)get:(NSString *)name options:(ARTChannelOptions *)options;

/**
 * BEGIN CANONICAL DOCSTRING
 * Releases a [`RestChannel`]{@link RestChannel} or [`RealtimeChannel`]{@link RealtimeChannel} object, deleting it, and enabling it to be garbage collected. It also removes any listeners associated with the channel. To release a channel, the [`ChannelState`]{@link ChannelState} must be `INITIALIZED`, `DETACHED`, or `FAILED`.
 *
 * @param name The channel name.
 * END CANONICAL DOCSTRING
 */
- (void)release:(NSString *)name;
- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(id (^)(ChannelType))mapper;

@end
