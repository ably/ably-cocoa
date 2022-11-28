#import <Foundation/Foundation.h>

#import "ARTWebSocket.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0))
@interface ARTURLSessionWebSocket : NSObject <ARTWebSocket, NSURLSessionWebSocketDelegate>

@end

NS_ASSUME_NONNULL_END
