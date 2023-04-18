#import "ARTRealtimeTransportFactory.h"
#import "ARTWebsocketTransport+Private.h"

@implementation ARTDefaultRealtimeTransportFactory

- (id<ARTRealtimeTransport>)transportWithRest:(ARTRestInternal *)rest options:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial logger:(ARTInternalLog *)logger {
    return [[ARTWebSocketTransport alloc] initWithRest:rest
                                               options:options
                                             resumeKey:resumeKey
                                      connectionSerial:connectionSerial
                                                logger:logger];
}

@end
