//
//  ARTEventEmitter.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

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

#pragma mark - ARTEventListener

@interface ARTEventListener : NSObject

@property (nonatomic, readonly) NSString *eventId;
@property (weak, nonatomic, readonly) id<NSObject> token;
@property (nonatomic, readonly) NSUInteger count;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithId:(NSString *)eventId token:(id<NSObject>)token handler:(ARTEventEmitter *)eventHandler center:(NSNotificationCenter *)center;

- (ARTEventListener *)setTimer:(NSTimeInterval)timeoutDeadline onTimeout:(void (^)())timeoutBlock;
- (void)startTimer;
- (void)stopTimer;

@end

#pragma mark - ARTEventEmitter

@interface ARTEventEmitter<EventType:id<ARTEventIdentification>, ItemType> : NSObject

- (instancetype)init;
- (instancetype)initWithQueue:(dispatch_queue_t)queue;

- (ARTEventListener *)on:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;
- (ARTEventListener *)on:(void (^)(ItemType __art_nullable))cb;

- (ARTEventListener *)once:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;
- (ARTEventListener *)once:(void (^)(ItemType __art_nullable))cb;

- (void)off:(EventType)event listener:(ARTEventListener *)listener;
- (void)off:(ARTEventListener *)listener;
- (void)off;

- (void)emit:(nullable EventType)event with:(nullable ItemType)data;

@end

// This macro adds methods to a class header file that mimic the API of an event emitter.
// This way you can automatically "implement the EventEmitter pattern" for a class
// as the spec says. It's supposed to be used together with ART_EMBED_IMPLEMENTATION_EVENT_EMITTER
// in the implementation of the class.
#define ART_EMBED_INTERFACE_EVENT_EMITTER(EventType, ItemType) - (ARTEventListener *)on:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;\
- (ARTEventListener *)on:(void (^)(ItemType __art_nullable))cb;\
\
- (ARTEventListener *)once:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;\
- (ARTEventListener *)once:(void (^)(ItemType __art_nullable))cb;\
\
- (void)off:(EventType)event listener:(ARTEventListener *)listener;\
- (void)off:(ARTEventListener *)listener;\
- (void)off;

// This macro adds methods to a class implementation that just bridge calls to an internal
// instance variable, which must be called _eventEmitter, of type ARTEventEmitter *.
// It's supposed to be used together with ART_EMBED_IMPLEMENTATION_EVENT_EMITTER in the
// header file of the class.
#define ART_EMBED_IMPLEMENTATION_EVENT_EMITTER(EventType, ItemType) - (ARTEventListener *)on:(EventType)event callback:(void (^)(ItemType __art_nullable))cb {\
return [_eventEmitter on:event callback:cb];\
}\
\
- (ARTEventListener *)on:(void (^)(ItemType __art_nullable))cb {\
return [_eventEmitter on:cb];\
}\
\
- (ARTEventListener *)once:(EventType)event callback:(void (^)(ItemType __art_nullable))cb {\
return [_eventEmitter once:event callback:cb];\
}\
\
- (ARTEventListener *)once:(void (^)(ItemType __art_nullable))cb {\
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
