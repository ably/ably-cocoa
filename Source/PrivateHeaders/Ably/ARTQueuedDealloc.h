#ifndef ARTQueuedDealloc_h
#define ARTQueuedDealloc_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTQueuedDealloc : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(id)ref queue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END

#endif /* ARTQueuedDealloc_h */
