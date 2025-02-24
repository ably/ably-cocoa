#import <Foundation/Foundation.h>

@class ARTRealtimeChannel;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTLiveObjectsPlugin <NSObject>

+ (void)prepareChannel:(ARTRealtimeChannel *)channel;

@end

NS_ASSUME_NONNULL_END
