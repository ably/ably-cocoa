#import <Foundation/Foundation.h>

@class ARTRealtimeChannel;

NS_ASSUME_NONNULL_BEGIN

// The `AblyLiveObjects.Plugin` class will _informally_ conform to this (informally so that we don't have to expose this protocol publicly); we keep this protocol simple because there will be no compiler checking
@protocol ARTLiveObjectsPluginFactory <NSObject>

- (id<ARTLiveObjectsPlugin>)createPlugin;

@end

// An internal class of `AblyLiveObjects` will conform to this; this protocol can be complex because compiler will check conformance
@protocol ARTLiveObjectsPlugin <NSObject>

- (void)prepareChannel:(ARTRealtimeChannel *)channel;

@end

NS_ASSUME_NONNULL_END
