#import <Foundation/Foundation.h>

@class ARTRest;
@class ARTRestChannel;
@class ARTChannelOptions;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Creates and destroys `ARTRestChannel` and `ARTRealtimeChannel` objects.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTChannels<ChannelType> : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Checks if a channel has been previously retrieved using the `-[ARTChannels get:]` method.
 *
 * @param name The channel name.
 *
 * @return `true` if the channel exists, otherwise `false`.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (BOOL)exists:(NSString *)name;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Creates a new `ARTRestChannel` or `ARTRealtimeChannel` object, or returns the existing channel object.
 *
 * @param name The channel name.
 *
 * @return A `ARTRestChannel` or `ARTRealtimeChannel` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (ChannelType)get:(NSString *)name;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Creates a new `ARTRestChannel` or `ARTRealtimeChannel` object, with the specified `ARTChannelOptions`, or returns the existing channel object.
 *
 * @param name The channel name.
 * @param options An `ARTChannelOptions` object.
 * 
 * @return A `ARTRestChannel` or `ARTRealtimeChannel` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (ChannelType)get:(NSString *)name options:(ARTChannelOptions *)options;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Releases an `ARTRestChannel` or an `ARTRealtimeChannel` object by deleting it. It also removes any listeners associated with the channel.
 * To release an `ARTRealtimeChannel` channel, the `-[ARTRealtimeChannel state]` must be `ARTRealtimeChannelInitialized`, `ARTRealtimeChannelDetached`, or `ARTRealtimeChannelFailed`.
 *
 * @param name The channel name.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (void)release:(NSString *)name;

/// :nodoc:
- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(id (^)(ChannelType))mapper;

@end
