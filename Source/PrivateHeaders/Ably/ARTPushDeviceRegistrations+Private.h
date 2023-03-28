#ifndef ARTPushDeviceRegistrations_Private_h
#define ARTPushDeviceRegistrations_Private_h

#import <Ably/ARTPushDeviceRegistrations.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;
@class ARTInternalLog;

@interface ARTPushDeviceRegistrationsInternal : NSObject <ARTPushDeviceRegistrationsProtocol>

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

@end

@interface ARTPushDeviceRegistrations ()

@property (nonatomic, readonly) ARTPushDeviceRegistrationsInternal *internal;

- (instancetype)initWithInternal:(ARTPushDeviceRegistrationsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

#endif /* ARTPushDeviceRegistrations_Private_h */
