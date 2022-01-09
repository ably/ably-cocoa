#import <Ably/ARTPushAdmin.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushAdminInternal : NSObject <ARTPushAdminProtocol>

- (instancetype)initWithRest:(ARTRestInternal *)rest;

@end

@interface ARTPushAdmin ()

@property (nonatomic, readonly) ARTPushAdminInternal *internal;

- (instancetype)initWithInternal:(ARTPushAdminInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
