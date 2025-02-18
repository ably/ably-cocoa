//
//  ARTRestChannel+Private.h
//
//

#import <Ably/ARTChannel.h>
#import <Ably/ARTRestChannel.h>
#import <Ably/ARTRestPresence+Private.h>
#import <Ably/ARTPushChannel+Private.h>
#import <Ably/ARTQueuedDealloc.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRestInternal;
@class ARTInternalLog;

@interface ARTRestChannelInternal : ARTChannel

@property (readonly) ARTRestPresenceInternal *presence;
@property (readonly) ARTPushChannelInternal *push;

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRestInternal *)rest logger:(ARTInternalLog *)logger;

@property (nonatomic, weak) ARTRestInternal *rest; // weak because rest owns self
@property (nonatomic) dispatch_queue_t queue;

@property (readonly, nullable) ARTChannelOptions *options;

- (BOOL)history:(nullable ARTDataQuery *)query wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTPaginatedMessagesCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)status:(ARTChannelDetailsCallback)callback;

- (void)setOptions:(ARTChannelOptions *_Nullable)options;

@end

@interface ARTRestChannelInternal (Private)

@property (readonly, getter=getBasePath) NSString *basePath;

@end

@interface ARTRestChannel ()

@property (nonatomic, readonly) ARTRestChannelInternal *internal;

- (instancetype)initWithInternal:(ARTRestChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

NS_ASSUME_NONNULL_END

@end
