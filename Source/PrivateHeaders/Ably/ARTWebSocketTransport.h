#import <Foundation/Foundation.h>
#import <Ably/ARTRealtimeTransport.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport : NSObject <ARTRealtimeTransport>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@property (readonly, nonatomic) NSString *resumeKey;

@end

NS_ASSUME_NONNULL_END
