//
//  ARTWebSocketTransport.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTWebSocketTransport.h"

#import "SwiftWebSocket-Swift.h"

#import "ARTRest.h"
#import "ARTRest+Private.h"
#import "ARTAuth.h"
#import "ARTProtocolMessage.h"
#import "ARTClientOptions.h"
#import "ARTTokenParams.h"
#import "ARTTokenDetails.h"
#import "ARTStatus.h"
#import "ARTEncoder.h"

enum {
    ARTWsNeverConnected = -1,
    ARTWsBuggyClose = -2,
    ARTWsCloseNormal = 1000,
    ARTWsGoingAway = 1001,
    ARTWsCloseProtocolError = 1002,
    ARTWsRefuse = 1003,
    ARTWsAbnormalClose = 1006,
    ARTWsNoUtf8 = 1007,
    ARTWsPolicyValidation = 1008,
    ARTWsTooBig = 1009,
    ARTWsExtension = 1010,
    ARTWsUnexpectedCondition = 1011,
    ARTWsTlsError = 1015
};

@interface ARTWebSocketTransport () <WebSocketDelegate>

@property (readonly, assign, nonatomic) CFRunLoopRef rl;
@property (readonly, strong, nonatomic) dispatch_queue_t queue;
@property (readwrite, strong, nonatomic) WebSocket *websocket;
@property (readwrite, assign, nonatomic) BOOL closing;

// From RestClient
@property (readwrite, strong, nonatomic) id<ARTEncoder> encoder;
@property (readonly, strong, nonatomic) ARTLog *logger;
@property (readonly, strong, nonatomic) ARTAuth *auth;
@property (readonly, strong, nonatomic) ARTClientOptions *options;
@property (readonly, strong, nonatomic) NSString *resumeKey;
@property (readonly, strong, nonatomic) NSNumber *connectionSerial;

@end

@implementation ARTWebSocketTransport

// FIXME: Realtime sould be extending from RestClient
- (instancetype)initWithRest:(ARTRest *)rest options:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial {
    self = [super init];
    if (self) {
        _rl = CFRunLoopGetCurrent();
        _queue = dispatch_queue_create("ARTWebSocketTransport", NULL);
        _websocket = nil;
        _closing = NO;

        _encoder = rest.defaultEncoder;
        _logger = rest.logger;
        _auth = rest.auth;
        _options = options;
        _resumeKey = resumeKey;
        _connectionSerial = connectionSerial;

        [self.logger debug:__FILE__ line:__LINE__ message:@"%p alloc", self];
    }
    return self;
}

- (void)dealloc {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p dealloc", self];
    self.websocket.delegate = nil;
    self.websocket = nil;
}

- (void)send:(ARTProtocolMessage *)msg {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p sending action %lu with %@", self, (unsigned long)msg.action, msg.messages];
    NSData *data = [self.encoder encodeProtocolMessage:msg];
    [self.websocket sendWithData:data];
}

- (void)receive:(ARTProtocolMessage *)msg {
    [self.delegate realtimeTransport:self didReceiveMessage:msg];
}

- (void)connect {
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p websocket connect", self];
    if ([self.options isBasicAuth]) {
        // Basic
        NSURLQueryItem *keyParam = [NSURLQueryItem queryItemWithName:@"key" value:self.options.key];
        [self setupWebSocket:@[keyParam] withOptions:self.options resumeKey:self.resumeKey connectionSerial:self.connectionSerial];
        // Connect
        [self.websocket open];
    }
    else {
        __weak ARTWebSocketTransport *selfWeak = self;
        // Token
        [self.auth authorise:nil options:self.options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
            ARTWebSocketTransport *selfStrong = selfWeak;
            if (!selfStrong) return;

            if (error) {
                [selfStrong.logger error:@"ARTWebSocketTransport: token auth failed with %@", error.description];
                [selfStrong.delegate realtimeTransportFailed:selfStrong withErrorInfo:[ARTErrorInfo createWithNSError:error]];
                return;
            }

            NSURLQueryItem *accessTokenParam = [NSURLQueryItem queryItemWithName:@"accessToken" value:(tokenDetails.token)];
            [selfStrong setupWebSocket:@[accessTokenParam] withOptions:selfStrong.options resumeKey:self.resumeKey connectionSerial:self.connectionSerial];
            // Connect
            [selfStrong.websocket open];
        }];
    } 
}

- (BOOL)getIsConnected {
    return self.websocket.readyState == WebSocketReadyStateOpen;
}

- (NSURL *)setupWebSocket:(__GENERIC(NSArray, NSURLQueryItem *) *)params withOptions:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial {
    NSArray *queryItems = params;

    // ClientID
    if (options.clientId) {
        NSURLQueryItem *clientIdParam = [NSURLQueryItem queryItemWithName:@"client_id" value:options.clientId];
        queryItems = [queryItems arrayByAddingObject:clientIdParam];
    }

    // Echo
    NSURLQueryItem *echoParam = [NSURLQueryItem queryItemWithName:@"echo" value:options.echoMessages ? @"true" : @"false"];
    queryItems = [queryItems arrayByAddingObject:echoParam];

    // Format: MsgPack, JSON
    NSURLQueryItem *formatParam = [NSURLQueryItem queryItemWithName:@"format" value:[_encoder formatAsString]];
    queryItems = [queryItems arrayByAddingObject:formatParam];

    if (options.recover) {
        NSArray *recoverParts = [options.recover componentsSeparatedByString:@":"];
        if ([recoverParts count] == 2) {
            NSString *key = [recoverParts objectAtIndex:0];
            NSString *serial = [recoverParts objectAtIndex:1];
            [self.logger info:@"ARTWebSocketTransport: attempting recovery of connection %@", key];

            NSURLQueryItem *recoverParam = [NSURLQueryItem queryItemWithName:@"recover" value:key];
            queryItems = [queryItems arrayByAddingObject:recoverParam];

            NSURLQueryItem *connectionSerialParam = [NSURLQueryItem queryItemWithName:@"connectionSerial" value:serial];
            queryItems = [queryItems arrayByAddingObject:connectionSerialParam];
        }
        else {
            [self.logger error:@"ARTWebSocketTransport: recovery string is malformed, ignoring: '%@'", options.recover];
        }
    }
    else if (resumeKey != nil && connectionSerial != nil) {
        NSURLQueryItem *resumeKeyParam = [NSURLQueryItem queryItemWithName:@"resume" value:resumeKey];
        queryItems = [queryItems arrayByAddingObject:resumeKeyParam];

        NSURLQueryItem *connectionSerialParam = [NSURLQueryItem queryItemWithName:@"connectionSerial" value:[NSString stringWithFormat:@"%lld", (long long)[connectionSerial integerValue]]];
        queryItems = [queryItems arrayByAddingObject:connectionSerialParam];
    }

    // URL
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:@"/"];
    urlComponents.queryItems = queryItems;
    NSURL *url = [urlComponents URLRelativeToURL:[options realtimeUrl]];

    [_logger debug:__FILE__ line:__LINE__ message:@"%p url %@", self, url];
    self.websocket = [[WebSocket alloc] initWithUrl:url];
    self.websocket.delegate = self;
    self.websocket.eventQueue = self.queue;
    return url;
}

- (void)sendClose {
    self.closing = YES;
    ARTProtocolMessage *closeMessage = [[ARTProtocolMessage alloc] init];
    closeMessage.action = ARTProtocolMessageClose;
    [self send:closeMessage];
}

- (void)sendPing {
    ARTProtocolMessage *closeMessage = [[ARTProtocolMessage alloc] init];
    closeMessage.action = ARTProtocolMessageHeartbeat;
    [self send:closeMessage];
}

- (void)close {
    if (!_websocket) return;
    self.websocket.delegate = nil;
    [self.websocket close:ARTWsCloseNormal reason:@"Normal Closure"];
    self.websocket = nil;
}

- (void)abort:(ARTStatus *)reason {
    if (!_websocket) return;
    self.websocket.delegate = nil;
    if (reason.errorInfo) {
        [self.websocket close:ARTWsAbnormalClose reason:reason.errorInfo.description];
    }
    else {
        [self.websocket close:ARTWsAbnormalClose reason:@"Abnormal Closure"];
    }
    self.websocket = nil;
}


#pragma mark - SRWebSocketDelegate

- (void)webSocketOpen {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p websocket did open", self];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s.delegate realtimeTransportAvailable:s];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketClose:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p websocket did disconnect (code %ld) %@", self, (long)code, reason];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (!s) {
            return;
        }

        switch (code) {
            case ARTWsCloseNormal:
                if (s.closing) {
                    // OK
                    [s.delegate realtimeTransportClosed:s];
                }
                break;
            case ARTWsNeverConnected:
                [s.delegate realtimeTransportNeverConnected:s];
                break;
            case ARTWsBuggyClose:
            case ARTWsGoingAway:
            case ARTWsAbnormalClose:
                // Connectivity issue
                [s.delegate realtimeTransportDisconnected:s];
                break;
            case ARTWsRefuse:
            case ARTWsPolicyValidation:
                [s.delegate realtimeTransportRefused:s];
                break;
            case ARTWsTooBig:
                [s.delegate realtimeTransportTooBig:s];
                break;
            case ARTWsNoUtf8:
            case ARTWsCloseProtocolError:
            case ARTWsUnexpectedCondition:
            case ARTWsExtension:
            case ARTWsTlsError:
                // Failed
                [s.delegate realtimeTransportFailed:s withErrorInfo:[ARTErrorInfo createWithCode:code message:reason]];
                break;
            default:
                NSAssert(true, @"WebSocket close: unknown code");
                break;
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketError:(NSError *)error {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p websocket did receive error %@", self, error];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s.delegate realtimeTransportFailed:s withErrorInfo:[ARTErrorInfo createWithNSError:error]];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketMessageText:(NSString *)text {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p websocket did receive message %@", self, text];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        NSData *data = nil;
        data = [((NSString *)text) dataUsingEncoding:NSUTF8StringEncoding];

        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            ARTProtocolMessage *pm = [s.encoder decodeProtocolMessage:data];
            [s receive:pm];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketMessageData:(NSData *)data {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"%p websocket did receive data %@", self, data];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            ARTProtocolMessage *pm = [s.encoder decodeProtocolMessage:data];
            [s receive:pm];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

@end
