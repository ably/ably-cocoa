#import <Ably/ARTChannels.h>
#import <Ably/ARTRealtimeChannel.h>
#import <Ably/ARTRealtime.h>

NS_ASSUME_NONNULL_BEGIN

/// :nodoc:
@protocol ARTRealtimeChannelsProtocol

// We copy this from the parent class and replace ChannelType by ARTRealtimeChannel * because
// Swift ignores Objective-C generics and thinks this is returning an id, failing to compile.
// Thus, we can't make ARTRealtimeChannels inherit from ARTChannels; we have to compose them instead.
- (BOOL)exists:(NSString *)name;
- (void)release:(NSString *)name callback:(nullable ARTCallback)errorInfo;
- (void)release:(NSString *)name;

@end

/// :nodoc:
@interface ARTRealtimeChannels : NSObject<ARTRealtimeChannelsProtocol>

- (ARTRealtimeChannel *)get:(NSString *)name;
- (ARTRealtimeChannel *)get:(NSString *)name options:(ARTRealtimeChannelOptions *)options;

/**
 * Iterates through the existing channels.
 *
 * @return Each iteration returns an `ARTRealtimeChannel` object.
 */
- (id<NSFastEnumeration>)iterate;

@end

NS_ASSUME_NONNULL_END
