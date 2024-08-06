#import <Ably/ARTPushAdmin.h>
#import <Ably/ARTPushDeviceRegistrations+Private.h>
#import <Ably/ARTPushChannelSubscriptions+Private.h>
#import <Ably/ARTQueuedDealloc.h>

@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(PushAdminInternal)
@interface ARTPushAdminInternal : NSObject <ARTPushAdminProtocol>

@property (nonatomic, readonly) ARTPushDeviceRegistrationsInternal *deviceRegistrations;
@property (nonatomic, readonly) ARTPushChannelSubscriptionsInternal *channelSubscriptions;

- (instancetype)initWithRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

@end

@interface ARTPushAdmin ()

@property (nonatomic, readonly) ARTPushAdminInternal *internal;

- (instancetype)initWithInternal:(ARTPushAdminInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
