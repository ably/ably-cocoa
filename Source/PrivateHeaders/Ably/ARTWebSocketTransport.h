#import <Foundation/Foundation.h>

#import <Ably/ARTRealtimeTransport.h>

@class ARTClientOptions;
@class ARTRest;

NS_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport : NSObject <ARTRealtimeTransport>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithRest:(ARTRestInternal *)rest options:(ARTClientOptions *)options resumeKey:(nullable NSString *)resumeKey connectionSerial:(nullable NSNumber *)connectionSerial logger:(ARTInternalLog *)logger NS_DESIGNATED_INITIALIZER;

@property (readonly, nonatomic) NSString *resumeKey;
@property (readonly, nonatomic) NSNumber *connectionSerial;

@end

NS_ASSUME_NONNULL_END
