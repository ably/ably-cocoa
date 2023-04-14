@import Foundation;

@class ARTRestInternal;
@class ARTClientOptions;
@class ARTInternalLog;
@protocol ARTRealtimeTransport;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(RealtimeTransportFactory)
@protocol ARTRealtimeTransportFactory

- (id<ARTRealtimeTransport>)transportWithRest:(ARTRestInternal *)rest
                                      options:(ARTClientOptions *)options
                                    resumeKey:(nullable NSString *)resumeKey
                             connectionSerial:(nullable NSNumber *)connectionSerial
                                       logger:(ARTInternalLog *)logger;

@end

NS_SWIFT_NAME(DefaultRealtimeTransportFactory)
@interface ARTDefaultRealtimeTransportFactory: NSObject<ARTRealtimeTransportFactory>
@end

NS_ASSUME_NONNULL_END
