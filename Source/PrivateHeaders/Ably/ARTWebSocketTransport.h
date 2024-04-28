#import <Foundation/Foundation.h>

#import <Ably/ARTRealtimeTransport.h>

@class ARTClientOptions;
@class ARTRest;
@protocol ARTWebSocketFactory;

NS_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport : NSObject <ARTRealtimeTransport>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithRest:(ARTRestInternal *)rest options:(ARTClientOptions *)options resumeKey:(nullable NSString *)resumeKey logger:(ARTInternalLog *)logger webSocketFactory:(id<ARTWebSocketFactory>)webSocketFactory NS_DESIGNATED_INITIALIZER;

@property (readonly, nonatomic) NSString *resumeKey;

@end

NS_ASSUME_NONNULL_END
