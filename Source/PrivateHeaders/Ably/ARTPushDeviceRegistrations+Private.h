#import <Ably/ARTPushDeviceRegistrations.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;

@interface ARTPushDeviceRegistrationsInternal : NSObject <ARTPushDeviceRegistrationsProtocol>

- (instancetype)initWithRest:(ARTRestInternal *)rest;

@end

@interface ARTPushDeviceRegistrations ()

@property (nonatomic, readonly) ARTPushDeviceRegistrationsInternal *internal;

- (instancetype)initWithInternal:(ARTPushDeviceRegistrationsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end
