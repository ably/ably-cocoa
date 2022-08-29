#import <Foundation/Foundation.h>

@class ARTRest;
@class ARTRestChannel;
@class ARTChannelOptions;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates and destroys `ARTRestChannel` and `ARTRealtimeChannel` objects.
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
 * Creates a new `ARTRestChannel` or `ARTRealtimeChannel` object, or returns the existing channel object.
 *
 * @param name The channel name.
 *
 * @return A `ARTRestChannel` or `ARTRealtimeChannel` object.
 * END CANONICAL DOCSTRING
 */
- (ChannelType)get:(NSString *)name;

/**
 * BEGIN CANONICAL DOCSTRING
 * Creates a new `ARTRestChannel` or `ARTRealtimeChannel` object, with the specified `ARTChannelOptions`, or returns the existing channel object.
 *
 * @param name The channel name.
 * @param options An `ARTChannelOptions` object.
 * 
 * @return A `ARTRestChannel` or `ARTRealtimeChannel` object.
 * END CANONICAL DOCSTRING
 */
- (ChannelType)get:(NSString *)name options:(ARTChannelOptions *)options;

/**
 * BEGIN CANONICAL DOCSTRING
 * Releases an `ARTRestChannel` or an `ARTRealtimeChannel` object by deleting it. It also removes any listeners associated with the channel.
 * To release an `ARTRealtimeChannel` channel, the `-[ARTRealtimeChannel state]` must be `ARTRealtimeChannelInitialized`, `ARTRealtimeChannelDetached`, or `ARTRealtimeChannelFailed`.
 *
 * @param name The channel name.
 * END CANONICAL DOCSTRING
 */
- (void)release:(NSString *)name;
- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(id (^)(ChannelType))mapper;

@end
