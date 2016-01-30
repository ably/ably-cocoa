//
//  ARTEventEmitter.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTTypes.h"

@class ARTRealtime;

ART_ASSUME_NONNULL_BEGIN

@interface __GENERIC(ARTEventListener, ItemType) : NSObject

- (void)call:(ItemType)argument;

@end

@interface __GENERIC(ARTEventEmitter, EventType, ItemType) : NSObject

- (__GENERIC(ARTEventListener, ItemType) *)on:(EventType)event call:(void (^)(ItemType))cb;
- (void)on:(EventType)event callListener:(__GENERIC(ARTEventListener, ItemType) *)listener;

- (__GENERIC(ARTEventListener, ItemType) *)onAll:(void (^)(ItemType))cb;
- (void)onAllCallListener:(__GENERIC(ARTEventListener, ItemType) *)listener;

- (__GENERIC(ARTEventListener, ItemType) *)once:(EventType)event call:(void (^)(ItemType))cb;
- (void)once:(EventType)event callListener:(__GENERIC(ARTEventListener, ItemType) *)listener;

- (__GENERIC(ARTEventListener, ItemType) *)onceAll:(void (^)(ItemType))cb;
- (void)onceAllCallListener:(__GENERIC(ARTEventListener, ItemType) *)listener;

- (void)off:(EventType)event listener:(__GENERIC(ARTEventListener, ItemType) *)listener;
- (void)offAll:(__GENERIC(ARTEventListener, ItemType) *)listener;

- (void)emit:(EventType)event with:(ItemType)data;

@end

// This macro adds methods to a class header file that mimic the API of an event emitter.
// This way you can automatically "implement the EventEmitter pattern" for a class
// as the spec say. It's supposed to be used together with ART_EMBED_IMPLEMENTATION_EVENT_EMITTER
// in the implementation of the class.
#define ART_EMBED_INTERFACE_EVENT_EMITTER(EventType, ItemType) - (__GENERIC(ARTEventListener, ItemType) *)on:(EventType)event call:(void (^)(ItemType))cb;\
- (void)on:(EventType)event callListener:(__GENERIC(ARTEventListener, ItemType) *)listener;\
\
- (__GENERIC(ARTEventListener, ItemType) *)onAll:(void (^)(ItemType))cb;\
- (void)onAllCallListener:(__GENERIC(ARTEventListener, ItemType) *)listener;\
\
- (__GENERIC(ARTEventListener, ItemType) *)once:(EventType)event call:(void (^)(ItemType))cb;\
- (void)once:(EventType)event callListener:(__GENERIC(ARTEventListener, ItemType) *)listener;\
\
- (__GENERIC(ARTEventListener, ItemType) *)onceAll:(void (^)(ItemType))cb;\
- (void)onceAllCallListener:(__GENERIC(ARTEventListener, ItemType) *)listener;\
\
- (void)off:(EventType)event listener:(__GENERIC(ARTEventListener, ItemType) *)listener;\
- (void)offAll:(__GENERIC(ARTEventListener, ItemType) *)listener;

// This macro adds methods to a class implementation that just bridge calls to an internal
// instance variable, which must be called _eventEmitter, of type ARTEventEmitter *.
// It's supposed to be used together with ART_EMBED_IMPLEMENTATION_EVENT_EMITTER in the
// header file of the class.
#define ART_EMBED_IMPLEMENTATION_EVENT_EMITTER(EventType, ItemType) - (__GENERIC(ARTEventListener, ItemType) *)on:(EventType)event call:(void (^)(ItemType))cb {\
return [_eventEmitter on:event call:cb];\
}\
\
- (void)on:(EventType)event callListener:(__GENERIC(ARTEventListener, ItemType) *)listener {\
[_eventEmitter on:event callListener:listener];\
}\
\
- (__GENERIC(ARTEventListener, ItemType) *)onAll:(void (^)(ItemType))cb {\
return [_eventEmitter onAll:cb];\
}\
\
- (void)onAllCallListener:(__GENERIC(ARTEventListener, ItemType) *)listener {\
[_eventEmitter onAllCallListener:(__GENERIC(ARTEventListener, ItemType) *)listener];\
}\
\
- (__GENERIC(ARTEventListener, ItemType) *)once:(EventType)event call:(void (^)(ItemType))cb {\
return [_eventEmitter once:event call:cb];\
}\
\
- (void)once:(EventType)event callListener:(__GENERIC(ARTEventListener, ItemType) *)listener {\
[_eventEmitter once:event callListener:listener];\
}\
\
- (__GENERIC(ARTEventListener, ItemType) *)onceAll:(void (^)(ItemType))cb {\
return [_eventEmitter onceAll:cb];\
}\
\
- (void)onceAllCallListener:(__GENERIC(ARTEventListener, ItemType) *)listener {\
[_eventEmitter onceAllCallListener:listener];\
}\
\
- (void)off:(EventType)event listener:listener {\
[_eventEmitter off:event listener:listener];\
}\
\
- (void)offAll:(__GENERIC(ARTEventListener, ItemType) *)listener {\
[_eventEmitter offAll:listener];\
}\
\
- (void)emit:(EventType)event with:(ItemType)data {\
[_eventEmitter emit:event with:data];\
}

ART_ASSUME_NONNULL_END
