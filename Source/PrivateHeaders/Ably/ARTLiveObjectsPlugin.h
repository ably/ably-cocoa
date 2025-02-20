#import <Foundation/Foundation.h>

@class ARTRealtimeChannel;

@protocol ARTLiveObjectsPlugin <NSObject>

+ (void)prepareChannel:(ARTRealtimeChannel *)channel;

@end
