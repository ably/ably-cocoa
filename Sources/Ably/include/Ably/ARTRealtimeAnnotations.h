#import <Foundation/Foundation.h>
#import <Ably/ARTAnnotation.h>
#import <Ably/ARTDataQuery.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol upon which the `ARTRealtimeAnnotations` is implemented.
 */
@protocol ARTRealtimeAnnotationsProtocol

/**
 * Registers a listener that is called each time an `ARTAnnotation` is received on the channel.
 *
 * Note that if you want to receive individual realtime annotations (instead of just the rolled-up summaries), you will need to request the `ARTChannelModeAnnotationSubscribe`  in `ARTChannelOptions`, since they are not delivered by default. In general, most clients will not bother with subscribing to individual annotations, and will instead just look at the summary updates.
 *
 * @param callback  A callback containing received annotation.
 *
 * @return An event listener object.
 */
- (ARTEventListener *_Nullable)subscribe:(ARTAnnotationCallback)callback;

/**
 * Registers a listener that is called each time an `ARTAnnotation` matching a given `type` is received on the channel.
 *
 * Note that if you want to receive individual realtime annotations (instead of just the rolled-up summaries), you will need to request the `ARTChannelModeAnnotationSubscribe` in `ARTChannelOptions`, since they are not delivered by default. In general, most clients will not bother with subscribing to individual annotations, and will instead just look at the summary updates.
 *
 * @param type A type of the `ARTAnnotation` to register the listener for.
 * @param callback  A callback containing received annotation.
 *
 * @return An event listener object.
 */
- (ARTEventListener *_Nullable)subscribe:(NSString *)type callback:(ARTAnnotationCallback)callback;

/**
 * Deregisters all listeners currently receiving `ARTAnnotation` for the channel.
 */
- (void)unsubscribe;

/**
 * Deregisters a specific listener that is registered to receive `ARTAnnotation` on the channel.
 *
 * @param listener An event listener to unsubscribe.
 */
- (void)unsubscribe:(ARTEventListener *)listener;

/**
 * Deregisters a specific listener that is registered to receive `ARTAnnotation` on the channel for a given type.
 *
 * @param type A specific annotation type to deregister the listeners for.
 * @param listener An event listener to unsubscribe.
 */
- (void)unsubscribe:(NSString *)type listener:(ARTEventListener *)listener;

@end

/**
 * @see See `ARTRealtimeAnnotationsProtocol` for details.
 */
NS_SWIFT_SENDABLE
@interface ARTRealtimeAnnotations : NSObject <ARTRealtimeAnnotationsProtocol>
@end

NS_ASSUME_NONNULL_END
