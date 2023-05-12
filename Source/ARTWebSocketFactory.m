#import "ARTWebSocketFactory.h"
#import "ARTSRWebSocket.h"

@implementation ARTDefaultWebSocketFactory

- (id<ARTWebSocket>)createWebSocketWithURLRequest:(NSURLRequest *)request logger:(ARTInternalLog *)logger {
    return [[ARTSRWebSocket alloc] initWithURLRequest:request logger:logger];
}

@end
