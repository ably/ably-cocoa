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

- (__GENERIC(ARTEventListener, ItemType) *)on:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;
- (__GENERIC(ARTEventListener, ItemType) *)on:(void (^)(ItemType __art_nullable))cb;

- (__GENERIC(ARTEventListener, ItemType) *)once:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;
- (__GENERIC(ARTEventListener, ItemType) *)once:(void (^)(ItemType __art_nullable))cb;

- (void)off:(EventType)event listener:(__GENERIC(ARTEventListener, ItemType) *)listener;
- (void)off:(__GENERIC(ARTEventListener, ItemType) *)listener;
- (void)off;

- (__GENERIC(ARTEventListener, ItemType) *)timed:(__GENERIC(ARTEventListener, ItemType) *)listener deadline:(NSTimeInterval)deadline onTimeout:(void (^__art_nullable)())onTimeout;

- (void)emit:(EventType)event with:(ItemType __art_nullable)data;

@end

// This macro adds methods to a class header file that mimic the API of an event emitter.
// This way you can automatically "implement the EventEmitter pattern" for a class
// as the spec says. It's supposed to be used together with ART_EMBED_IMPLEMENTATION_EVENT_EMITTER
// in the implementation of the class.
#define ART_EMBED_INTERFACE_EVENT_EMITTER(EventType, ItemType) - (__GENERIC(ARTEventListener, ItemType) *)on:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;\
- (__GENERIC(ARTEventListener, ItemType) *)on:(void (^)(ItemType __art_nullable))cb;\
\
- (__GENERIC(ARTEventListener, ItemType) *)once:(EventType)event callback:(void (^)(ItemType __art_nullable))cb;\
- (__GENERIC(ARTEventListener, ItemType) *)once:(void (^)(ItemType __art_nullable))cb;\
\
- (void)off:(EventType)event listener:(__GENERIC(ARTEventListener, ItemType) *)listener;\
- (void)off:(__GENERIC(ARTEventListener, ItemType) *)listener;\
- (void)off;\
\
- (__GENERIC(ARTEventListener, ItemType) *)timed:(__GENERIC(ARTEventListener, ItemType) *)listener deadline:(NSTimeInterval)deadline onTimeout:(void (^__art_nullable)())onTimeout;

// This macro adds methods to a class implementation that just bridge calls to an internal
// instance variable, which must be called _eventEmitter, of type ARTEventEmitter *.
// It's supposed to be used together with ART_EMBED_IMPLEMENTATION_EVENT_EMITTER in the
// header file of the class.
#define ART_EMBED_IMPLEMENTATION_EVENT_EMITTER(EventType, ItemType) - (__GENERIC(ARTEventListener, ItemType) *)on:(EventType)event callback:(void (^)(ItemType __art_nullable))cb {\
return [_eventEmitter on:event callback:cb];\
}\
\
- (__GENERIC(ARTEventListener, ItemType) *)on:(void (^)(ItemType __art_nullable))cb {\
return [_eventEmitter on:cb];\
}\
\
- (__GENERIC(ARTEventListener, ItemType) *)once:(EventType)event callback:(void (^)(ItemType __art_nullable))cb {\
return [_eventEmitter once:event callback:cb];\
}\
\
- (__GENERIC(ARTEventListener, ItemType) *)once:(void (^)(ItemType __art_nullable))cb {\
return [_eventEmitter once:cb];\
}\
\
- (void)off:(EventType)event listener:listener {\
[_eventEmitter off:event listener:listener];\
}\
\
- (void)off:(__GENERIC(ARTEventListener, ItemType) *)listener {\
[_eventEmitter off:listener];\
}\
- (void)off {\
[_eventEmitter off];\
}\
- (__GENERIC(ARTEventListener, ItemType) *)timed:(__GENERIC(ARTEventListener, ItemType) *)listener deadline:(NSTimeInterval)deadline onTimeout:(void (^)())onTimeout {\
return [_eventEmitter timed:listener deadline:deadline onTimeout:onTimeout];\
}\
\
- (void)emit:(EventType)event with:(ItemType)data {\
[_eventEmitter emit:event with:data];\
}

ART_ASSUME_NONNULL_END
