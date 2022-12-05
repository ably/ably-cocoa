#import <Foundation/Foundation.h>

#import "ARTWebSocket.h"

@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0))
@interface ARTURLSessionWebSocket : NSObject <ARTWebSocket, NSURLSessionWebSocketDelegate>

@property (readonly, strong, nonatomic) ARTLog *logger;

@end

NS_ASSUME_NONNULL_END
