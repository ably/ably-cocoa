#import <Foundation/Foundation.h>
#import "APRealtimeChannel.h"

@class ARTRealtimeChannelInternal;

NS_ASSUME_NONNULL_START

@interface ARTPluginRealtimeChannel : NSObject<APRealtimeChannel>

- (instancetype)initWithUnderlying:(ARTRealtimeChannelInternal *)underlying;

@end

NS_ASSUME_NONNULL_END
