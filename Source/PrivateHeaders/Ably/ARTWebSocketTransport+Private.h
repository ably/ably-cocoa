#import <Ably/ARTWebSocketTransport.h>
#import "ARTSRWebSocket.h"
#import <Ably/ARTEncoder.h>
#import <Ably/ARTAuth.h>
#import <Ably/ARTWebSocket.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport () <ARTWebSocketDelegate>

// From RestClient
@property (readwrite, nonatomic) id<ARTEncoder> encoder;
@property (readonly, nonatomic) ARTInternalLog *logger;
@property (readonly, nonatomic) ARTClientOptions *options;

@property (readwrite, nonatomic, nullable) id<ARTWebSocket> websocket;
@property (readwrite, nonatomic, nullable) NSURL *websocketURL;

- (NSURL *)setupWebSocket:(NSDictionary<NSString *, NSURLQueryItem *> *)params withOptions:(ARTClientOptions *)options resumeKey:(NSString *_Nullable)resumeKey;

- (void)setState:(ARTRealtimeTransportState)state;

@end

#pragma mark - ARTEvent

@interface ARTEvent (TransportState)
- (instancetype)initWithTransportState:(ARTRealtimeTransportState)value;
+ (instancetype)newWithTransportState:(ARTRealtimeTransportState)value;

@end

NS_ASSUME_NONNULL_END
