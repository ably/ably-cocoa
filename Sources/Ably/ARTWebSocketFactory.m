#import "ARTWebSocketFactory.h"
#import "ARTSRWebSocket.h"
#import "ARTInternalLog.h"

// TODO
@interface ARTInternalLog (ARTSRInternalLog) <ARTSRInternalLog>
@end

@implementation ARTDefaultWebSocketFactory

- (id<ARTWebSocket>)createWebSocketWithURLRequest:(NSURLRequest *)request logger:(ARTInternalLog *)logger {
    return [[ARTSRWebSocket alloc] initWithURLRequest:request logger:logger];
}

@end
