#import <Ably/ARTRestPresence.h>
#import <Ably/ARTQueuedDealloc.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRestChannelInternal;
@class ARTInternalLog;

@interface ARTRestPresenceInternal : NSObject

- (instancetype)initWithChannel:(ARTRestChannelInternal *)channel logger:(ARTInternalLog *)logger;

- (void)get:(ARTPaginatedPresenceCallback)callback;

- (BOOL)get:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)get:(ARTPresenceQuery *)query callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)history:(nullable ARTDataQuery *)query wrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents callback:(ARTPaginatedPresenceCallback)callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (void)historyWithWrapperSDKAgents:(nullable NSStringDictionary *)wrapperSDKAgents
                         completion:(ARTPaginatedPresenceCallback)callback;

@end

@interface ARTRestPresence ()

@property (nonatomic, readonly) ARTRestPresenceInternal *internal;

- (instancetype)initWithInternal:(ARTRestPresenceInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
