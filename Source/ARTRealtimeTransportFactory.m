#import "ARTRealtimeTransportFactory.h"
#import "ARTWebsocketTransport+Private.h"

@implementation ARTDefaultRealtimeTransportFactory

- (id<ARTRealtimeTransport>)transportWithRest:(ARTRestInternal *)rest options:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey logger:(ARTInternalLog *)logger {
    return [[ARTWebSocketTransport alloc] initWithRest:rest
                                               options:options
                                             resumeKey:resumeKey
                                                logger:logger];
}

@end
