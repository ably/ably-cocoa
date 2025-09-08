#import <Foundation/Foundation.h>

@class ARTRealtime;
@class ARTEventEmitter;

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@protocol ARTEventIdentification
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (NSString *)identification;
@end

/// :nodoc:
@interface ARTEvent : NSObject<ARTEventIdentification>

- (instancetype)initWithString:(NSString *)value;
+ (instancetype)newWithString:(NSString *)value;

@end

/**
 An object representing a listener returned by `ARTEventEmitter` methods.
 */
NS_SWIFT_SENDABLE
@interface ARTEventListener : NSObject
@end

/**
 * A generic interface for event registration and delivery used in a number of the types in the Realtime client library. For example, the `ARTConnection` and `ARTRealtimeChannel` objects emit events for their state using the `ARTEventEmitter` pattern.
 */
NS_SWIFT_SENDABLE
@interface ARTEventEmitter<EventType:id<ARTEventIdentification>, ItemType> : NSObject

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 * Registers the provided listener for the specified event. If `on:callback:` is called more than once with the same listener and event, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `on:callback:`, and an event is emitted once, the listener would be invoked twice.
 *
 * @param event The named event to listen for.
 * @param callback A callback invoked upon `event` with an `ItemType` object, f.e. `ARTConnectionStateChange`.
 *
 * @return The event listener.
 */
- (ARTEventListener *)on:(EventType)event callback:(void (^)(ItemType))callback;

/**
 * Registers the provided listener all events. If `on:` is called more than once with the same listener and event, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `on:`, and an event is emitted once, the listener would be invoked twice.
 *
 * @param callback A callback invoked upon any event with an `ItemType` object, f.e. `ARTConnectionStateChange`.
 *
 * @return The event listener.
 */
- (ARTEventListener *)on:(void (^)(ItemType))callback;

/**
 * Registers the provided listener for the first occurrence of a single named event specified as the `event` argument. If `once:callback:` is called more than once with the same listener, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `once:callback:`, and an event is emitted once, the listener would be invoked twice. However, all subsequent events emitted would not invoke the listener as `once:callback:` ensures that each registration is only invoked once.
 *
 * @param event The named event to listen for.
 * @param callback A callback invoked upon `event` with an `ItemType` object, f.e. `ARTConnectionStateChange`.
 *
 * @return The event listener.
 */
- (ARTEventListener *)once:(EventType)event callback:(void (^)(ItemType))callback;

/**
 * Registers the provided listener for the first event that is emitted. If `once:` is called more than once with the same listener, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `once:`, and an event is emitted once, the listener would be invoked twice. However, all subsequent events emitted would not invoke the listener as `once:` ensures that each registration is only invoked once.
 *
 * @param callback A callback invoked upon any event with an `ItemType` object, f.e. `ARTConnectionStateChange`.
 *
 * @return The event listener.
 */
- (ARTEventListener *)once:(void (^)(ItemType))callback;

/**
 * Removes all registrations that match both the specified listener and the specified event.
 *
 * @param event The named event.
 * @param listener The event listener.
 */
- (void)off:(EventType)event listener:(ARTEventListener *)listener;

/**
 * Deregisters the specified listener. Removes all registrations matching the given listener, regardless of whether they are associated with an event or not.
 *
 * @param listener The event listener.
 */
- (void)off:(ARTEventListener *)listener;

/**
 * Deregisters all registrations, for all events and listeners.
 */
- (void)off;

@end


NS_ASSUME_NONNULL_END
