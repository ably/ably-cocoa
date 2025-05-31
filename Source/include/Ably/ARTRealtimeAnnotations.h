#import <Foundation/Foundation.h>
#import <Ably/ARTAnnotation.h>
#import <Ably/ARTRestAnnotations.h>
#import <Ably/ARTDataQuery.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTRealtimeAnnotations` is implemented.
 */
@protocol ARTRealtimeAnnotationsProtocol

/**
 * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceAction.ARTPresenceEnter` event. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param annotation The payload to update for the presence member.
 * @param callback A success or failure callback function.
 */
- (void)publish:(ARTAnnotation *)annotation callback:(nullable ARTAnnotationErrorCallback)callback;

/**
 * Updates the `data` payload for a presence member. If called before entering the presence set, this is treated as an `ARTPresenceAction.ARTPresenceEnter` event. An optional callback may be provided to notify of the success or failure of the operation.
 *
 * @param annotation The payload to update for the presence member.
 * @param callback A success or failure callback function.
 */
- (void)unpublish:(ARTAnnotation *)annotation callback:(nullable ARTAnnotationErrorCallback)callback;

/**
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns an array of `ARTPresenceMessage` objects.
 *
 * @param query An `ARTRealtimeAnnotationsQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 */
- (void)getForMessage:(ARTMessage *)message query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback;

/**
 * Retrieves the current members present on the channel and the metadata for each member, such as their `ARTPresenceAction` and ID. Returns an array of `ARTPresenceMessage` objects.
 *
 * @param query An `ARTRealtimeAnnotationsQuery` object.
 * @param callback A callback for retriving an `ARTPaginatedResult` object with an array of `ARTPresenceMessage` objects.
 */
- (void)getForMessageSerial:(NSString *)messageSerial query:(ARTAnnotationsQuery *)query callback:(ARTPaginatedAnnotationsCallback)callback;

/**
 * Registers a listener that is called each time a `ARTAnnotation` is received on the channel, such as a new member entering the presence set.
 *
 * @param callback An event listener function.
 *
 * @return An event listener object.
 */
- (ARTEventListener *_Nullable)subscribe:(ARTAnnotationCallback)callback;

/**
 * Registers a listener that is called each time a `ARTPresenceMessage` matching a given `ARTPresenceAction` is received on the channel, such as a new member entering the presence set.
 *
 * @param type A type of the `ARTAnnotation` to register the listener for.
 * @param callback An event listener function.
 *
 * @return An event listener object.
 */
- (ARTEventListener *_Nullable)subscribe:(NSString *)type callback:(ARTAnnotationCallback)callback;

/**
 * Deregisters all listeners currently receiving `ARTPresenceMessage` for the channel.
 */
- (void)unsubscribe;

/**
 * Deregisters a specific listener that is registered to receive `ARTPresenceMessage` on the channel.
 *
 * @param listener An event listener to unsubscribe.
 */
- (void)unsubscribe:(ARTEventListener *)listener;

/**
 * Deregisters a specific listener that is registered to receive `ARTPresenceMessage` on the channel for a given `ARTPresenceAction`.
 *
 * @param type A specific type of the `ARTAnnotation` to deregister the listener for.
 * @param listener An event listener to unsubscribe.
 */
- (void)unsubscribe:(NSString *)type listener:(ARTEventListener *)listener;

@end

/**
 * Enables the presence set to be entered and subscribed to, and the historic presence set to be retrieved for a channel.
 *
 * @see See `ARTRealtimeAnnotationsProtocol` for details.
 */
NS_SWIFT_SENDABLE
@interface ARTRealtimeAnnotations : NSObject <ARTRealtimeAnnotationsProtocol>
@end

NS_ASSUME_NONNULL_END
