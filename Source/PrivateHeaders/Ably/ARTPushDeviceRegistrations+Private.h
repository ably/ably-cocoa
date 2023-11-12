#import <Ably/ARTPushDeviceRegistrations.h>
#import <Ably/ARTQueuedDealloc.h>

@class ARTRestInternal;
@class ARTInternalLog;

@interface ARTPushDeviceRegistrationsInternal : NSObject <ARTPushDeviceRegistrationsProtocol>

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

@end

@interface ARTPushDeviceRegistrations ()

@property (nonatomic, readonly) ARTPushDeviceRegistrationsInternal *internal;

- (instancetype)initWithInternal:(ARTPushDeviceRegistrationsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end
