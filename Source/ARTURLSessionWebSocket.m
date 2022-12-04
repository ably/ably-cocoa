#import "ARTURLSessionWebSocket.h"

@interface ARTURLSessionWebSocket ()

@property (atomic, assign, readwrite) ARTWebSocketState readyState;

@end

@implementation ARTURLSessionWebSocket {
    NSURLSession *_urlSession;
    NSURLSessionWebSocketTask *_webSocketTask;
    dispatch_queue_t _delegateQueue;
}

@synthesize delegate = _delegate;
@synthesize readyState = _readyState;
@synthesize delegateDispatchQueue = _delegateDispatchQueue;

- (nonnull instancetype)initWithURLRequest:(nonnull NSURLRequest *)request {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        _webSocketTask = [_urlSession webSocketTaskWithRequest:request];
        _readyState = ARTWS_CLOSED;
    }
    return self;
}

- (void)setDelegateDispatchQueue:(nonnull dispatch_queue_t)queue {
    _delegateQueue = queue;
}

- (void)listenForMessage {
    [_webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage *message, NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error);
            return;
        }
        dispatch_async(self->_delegateQueue, ^{
            switch (message.type) {
                case NSURLSessionWebSocketMessageTypeData:
                    [self->_delegate webSocket:self didReceiveMessage:[message data]];
                    break;
                case NSURLSessionWebSocketMessageTypeString:
                    [self->_delegate webSocket:self didReceiveMessage:[message string]];
                    break;
            }
        });
        [self listenForMessage];
    }];
}

- (void)open {
    assert(_delegateQueue);
    _readyState = ARTWS_CONNECTING;
    [self listenForMessage];
    [_webSocketTask resume];
}

- (void)send:(nullable id)data {
    NSURLSessionWebSocketMessage *wsMessage = [data isKindOfClass:[NSString class]] ?
                                                [[NSURLSessionWebSocketMessage alloc] initWithString:data] :
                                                [[NSURLSessionWebSocketMessage alloc] initWithData:data];
    [_webSocketTask sendMessage:wsMessage completionHandler: ^(NSError *error) {
        dispatch_async(self->_delegateQueue, ^{
            if (error != nil) {
                [self->_delegate webSocket:self didFailWithError:error];
            }
        });
    }];
}

- (void)closeWithCode:(NSInteger)code reason:(nullable NSString *)reason {
    if (self.readyState != ARTWS_CLOSED) {
        self.readyState = ARTWS_CLOSING;
    }
    [_webSocketTask cancelWithCloseCode:code reason:[reason dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *) protocol {
    self.readyState = ARTWS_OPEN;
    dispatch_async(self->_delegateQueue, ^{
        [self->_delegate webSocketDidOpen:self];
    });
}

- (void)URLSession:(NSURLSession *)session
     webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask
  didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reasonData {
    if (self.readyState == ARTWS_CLOSING || self.readyState == ARTWS_OPEN) {
        self.readyState = ARTWS_CLOSED;
    }
    dispatch_async(self->_delegateQueue, ^{
        NSString *reason = [[NSString alloc] initWithData:reasonData encoding:NSUTF8StringEncoding];
        [self->_delegate webSocket:self didCloseWithCode:closeCode reason:reason wasClean:YES];
    });
}

@end
