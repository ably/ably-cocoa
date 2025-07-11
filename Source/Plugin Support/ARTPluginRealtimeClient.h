#import <Foundation/Foundation.h>
#import "APRealtimeClient.h"

@class ARTRealtimeInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPluginRealtimeClient : NSObject<APRealtimeClient>

- (instancetype)initWithUnderlying:(ARTRealtimeInternal *)underlying;

@end

NS_ASSUME_NONNULL_END
