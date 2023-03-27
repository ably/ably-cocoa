#import <Foundation/Foundation.h>

#import <Ably/ARTRealtimeTransport.h>

@class ARTClientOptions;
@class ARTRest;

NS_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport : NSObject <ARTRealtimeTransport>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@property (readonly, strong, nonatomic) NSString *resumeKey;
@property (readonly, strong, nonatomic) NSNumber *connectionSerial;

@end

NS_ASSUME_NONNULL_END
