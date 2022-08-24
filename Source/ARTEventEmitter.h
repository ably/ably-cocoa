#import <Foundation/Foundation.h>

@class ARTRealtime;
@class ARTEventEmitter;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTEventIdentification
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (NSString *)identification;
@end

@interface ARTEvent : NSObject<ARTEventIdentification>

- (instancetype)initWithString:(NSString *)value;
+ (instancetype)newWithString:(NSString *)value;

@end

@interface ARTEventListener : NSObject
@end

#pragma mark - ARTEventEmitter

/**
 * BEGIN CANONICAL DOCSTRING
 * A generic interface for event registration and delivery used in a number of the types in the Realtime client library. For example, the `ARTConnection` object emits events for connection state using the `EventEmitter` pattern.
 * END CANONICAL DOCSTRING
 */
@interface ARTEventEmitter<EventType:id<ARTEventIdentification>, ItemType> : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers the provided listener for the specified event. If `on:callback:` is called more than once with the same listener and event, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `on:callback:`, and an event is emitted once, the listener would be invoked twice.
 *
 * @param event The named event to listen for.
 *
 * @return The event listener.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *)on:(EventType)event callback:(void (^)(ItemType))cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers the provided listener all events. If `on:` is called more than once with the same listener and event, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `on:`, and an event is emitted once, the listener would be invoked twice.
 *
 * @return The event listener.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *)on:(void (^)(ItemType))cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers the provided listener for the first occurrence of a single named event specified as the `Event` argument. If `once()` is called more than once with the same listener, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `once:callback:`, and an event is emitted once, the listener would be invoked twice. However, all subsequent events emitted would not invoke the listener as `once:callback:` ensures that each registration is only invoked once.
 *
 * @param event The named event to listen for.
 *
 * @return The event listener.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *)once:(EventType)event callback:(void (^)(ItemType))cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Registers the provided listener for the first event that is emitted. If `once:` is called more than once with the same listener, the listener is added multiple times to its listener registry. Therefore, as an example, assuming the same listener is registered twice using `once:`, and an event is emitted once, the listener would be invoked twice. However, all subsequent events emitted would not invoke the listener as `once:` ensures that each registration is only invoked once.
 *
 * @return The event listener.
 * END CANONICAL DOCSTRING
 */
- (ARTEventListener *)once:(void (^)(ItemType))cb;

/**
 * BEGIN CANONICAL DOCSTRING
 * Removes all registrations that match both the specified listener and the specified event.
 *
 * @param event The named event.
 * @param listener The event listener.
 * END CANONICAL DOCSTRING
 */
- (void)off:(EventType)event listener:(ARTEventListener *)listener;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters the specified listener. Removes all registrations matching the given listener, regardless of whether they are associated with an event or not.
 *
 * @param listener The event listener.
 * END CANONICAL DOCSTRING
 */
- (void)off:(ARTEventListener *)listener;

/**
 * BEGIN CANONICAL DOCSTRING
 * Deregisters all registrations, for all events and listeners.
 * END CANONICAL DOCSTRING
 */
- (void)off;

@end

// This macro adds methods to a class header file that mimic the API of an event emitter.
// This way you can automatically "implement the EventEmitter pattern" for a class
// as the spec says. It's supposed to be used together with ART_EMBED_IMPLEMENTATION_EVENT_EMITTER
// in the implementation of the class.
#define ART_EMBED_INTERFACE_EVENT_EMITTER(EventType, ItemType) - (ARTEventListener *)on:(EventType)event callback:(void (^)(ItemType))cb;\
- (ARTEventListener *)on:(void (^)(ItemType))cb;\
\
- (ARTEventListener *)once:(EventType)event callback:(void (^)(ItemType))cb;\
- (ARTEventListener *)once:(void (^)(ItemType))cb;\
\
- (void)off:(EventType)event listener:(ARTEventListener *)listener;\
- (void)off:(ARTEventListener *)listener;\
- (void)off;

// This macro adds methods to a class implementation that just bridge calls to an internal
// instance variable, which must be called _eventEmitter, of type ARTEventEmitter *.
// It's supposed to be used together with ART_EMBED_INTERFACE_EVENT_EMITTER in the
// header file of the class.
#define ART_EMBED_IMPLEMENTATION_EVENT_EMITTER(EventType, ItemType) - (ARTEventListener *)on:(EventType)event callback:(void (^)(ItemType))cb {\
return [_eventEmitter on:event callback:cb];\
}\
\
- (ARTEventListener *)on:(void (^)(ItemType))cb {\
return [_eventEmitter on:cb];\
}\
\
- (ARTEventListener *)once:(EventType)event callback:(void (^)(ItemType))cb {\
return [_eventEmitter once:event callback:cb];\
}\
\
- (ARTEventListener *)once:(void (^)(ItemType))cb {\
return [_eventEmitter once:cb];\
}\
\
- (void)off:(EventType)event listener:(ARTEventListener *)listener {\
[_eventEmitter off:event listener:listener];\
}\
\
- (void)off:(ARTEventListener *)listener {\
[_eventEmitter off:listener];\
}\
- (void)off {\
[_eventEmitter off];\
}\
\
- (void)emit:(EventType)event with:(ItemType)data {\
[_eventEmitter emit:event with:data];\
}

NS_ASSUME_NONNULL_END
