#import "ARTURLSessionWebSocket.h"
#import "ARTLog.h"

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
@synthesize logger = _logger;

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
    __weak ARTURLSessionWebSocket *weakSelf = self;
    [_webSocketTask receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage *message, NSError *error) {
        ARTURLSessionWebSocket *strongSelf = weakSelf;
        if (strongSelf) {
            dispatch_async(strongSelf->_delegateQueue, ^{
                /*
                 * We will ignore `error` object here, relying only on `message` object presence, since:
                 * 1) there is additional handler for connectivity issues (`URLSession:task:didCompleteWithError:`) and
                 * 2) the `ARTWebSocketTransport` is not very welcoming for error emerging from here, causing some tests to fail.
                 */
                if (error != nil) {
                    [strongSelf->_logger debug:__FILE__ line:__LINE__ message:@"Receive message error: %@, task state = %@", error, @(strongSelf->_webSocketTask.state)];
                }
                if (message != nil) {
                    switch (message.type) {
                        case NSURLSessionWebSocketMessageTypeData:
                            [strongSelf->_delegate webSocket:strongSelf didReceiveMessage:[message data]];
                            break;
                        case NSURLSessionWebSocketMessageTypeString:
                            [strongSelf->_delegate webSocket:strongSelf didReceiveMessage:[message string]];
                            break;
                    }
                }
                if (strongSelf.readyState == ARTWS_OPEN) {
                    [strongSelf listenForMessage];
                }
            });
        }
    }];
}

- (void)open {
    assert(_delegateQueue);
    _readyState = ARTWS_CONNECTING;
    [_webSocketTask resume];
}

- (void)send:(nullable id)data {
    assert(_delegateQueue);
    NSURLSessionWebSocketMessage *wsMessage = [data isKindOfClass:[NSString class]] ?
                                                [[NSURLSessionWebSocketMessage alloc] initWithString:data] :
                                                [[NSURLSessionWebSocketMessage alloc] initWithData:data];
    __weak ARTURLSessionWebSocket *weakSelf = self;
    [_webSocketTask sendMessage:wsMessage completionHandler:^(NSError *error) {
        ARTURLSessionWebSocket *strongSelf = weakSelf;
        if (strongSelf) {
            dispatch_async(strongSelf->_delegateQueue, ^{
                if (error != nil) {
                    [strongSelf->_delegate webSocket:strongSelf didFailWithError:error];
                }
            });
        }
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
    [self listenForMessage];
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

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    self.readyState = ARTWS_CLOSED;
    if (error != nil) {
        [_logger debug:__FILE__ line:__LINE__ message:@"Session completion error: %@, task state = %@", error, @(_webSocketTask.state)];
        dispatch_async(self->_delegateQueue, ^{
            [self->_delegate webSocket:self didFailWithError:error];
        });
    }
    else {
        [_logger debug:__FILE__ line:__LINE__ message:@"Session completion task state = %@", @(_webSocketTask.state)];
    }
}

@end
