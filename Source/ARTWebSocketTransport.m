//
//  ARTWebSocketTransport.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTWebSocketTransport+Private.h"

#import "ARTRest.h"
#import "ARTRest+Private.h"
#import "ARTAuth.h"
#import "ARTProtocolMessage.h"
#import "ARTClientOptions.h"
#import "ARTTokenParams.h"
#import "ARTTokenDetails.h"
#import "ARTStatus.h"
#import "ARTEncoder.h"
#import "ARTDefault.h"
#import "ARTRealtimeTransport.h"

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

@implementation ARTWebSocketTransport

// FIXME: Realtime sould be extending from RestClient
- (instancetype)initWithRest:(ARTRest *)rest options:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial {
    self = [super init];
    if (self) {
        _rl = CFRunLoopGetCurrent();
        _websocket = nil;
        _closing = NO;

        _encoder = rest.defaultEncoder;
        _logger = rest.logger;
        _auth = rest.auth;
        _options = [options copy];
        _resumeKey = resumeKey;
        _connectionSerial = connectionSerial;

        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p alloc", _delegate, self];
    }
    return self;
}

- (void)dealloc {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p dealloc", _delegate, self];
    self.websocket.delegate = nil;
    self.websocket = nil;
}

- (void)send:(ARTProtocolMessage *)msg {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p sending action %lu with %@", _delegate, self, (unsigned long)msg.action, msg.messages];
    NSData *data = [self.encoder encodeProtocolMessage:msg];
    [self sendWithData:data];
}

- (void)sendWithData:(NSData *)data {
    [self.websocket send:data];
}

- (void)receive:(ARTProtocolMessage *)msg {
    [self.delegate realtimeTransport:self didReceiveMessage:msg];
}

- (void)receiveWithData:(NSData *)data {
    ARTProtocolMessage *pm = [self.encoder decodeProtocolMessage:data];
    [self receive:pm];
}

- (void)connect {
    [self connectForcingNewToken:false];
}

- (void)connectForcingNewToken:(BOOL)forceNewToken {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p websocket connect", _delegate, self];
    ARTClientOptions *options = self.options;
    if (forceNewToken) {
        options = [options copy];
        options.force = true;
    }
    if ([options isBasicAuth]) {
        // Basic
        NSURLQueryItem *keyParam = [NSURLQueryItem queryItemWithName:@"key" value:options.key];
        [self setupWebSocket:@[keyParam] withOptions:options resumeKey:self.resumeKey connectionSerial:self.connectionSerial];
        // Connect
        [self.websocket open];
    }
    else {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p connecting with token auth; authorising", _delegate, self];
        __weak ARTWebSocketTransport *selfWeak = self;
        // Token
        [self.auth authorise:nil options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
            [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p authorised: %@ error: %@", _delegate, self, tokenDetails, error];
            ARTWebSocketTransport *selfStrong = selfWeak;
            if (!selfStrong) return;

            if (error) {
                [selfStrong.logger error:@"R:%p WS:%p ARTWebSocketTransport: token auth failed with %@", _delegate, self, error.description];
                [selfStrong.delegate realtimeTransportFailed:selfStrong withError:[[ARTRealtimeTransportError alloc] initWithError:error type:ARTRealtimeTransportErrorTypeAuth url:self.websocketURL]];
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
    return self.websocket.readyState == SR_OPEN;
}

- (NSURL *)setupWebSocket:(__GENERIC(NSArray, NSURLQueryItem *) *)params withOptions:(ARTClientOptions *)options resumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial {
    NSArray *queryItems = params;

    // ClientID
    if (options.clientId) {
        NSURLQueryItem *clientIdParam = [NSURLQueryItem queryItemWithName:@"clientId" value:options.clientId];
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
            [self.logger info:@"R:%p WS:%p ARTWebSocketTransport: attempting recovery of connection %@", _delegate, self, key];

            NSURLQueryItem *recoverParam = [NSURLQueryItem queryItemWithName:@"recover" value:key];
            queryItems = [queryItems arrayByAddingObject:recoverParam];

            NSURLQueryItem *connectionSerialParam = [NSURLQueryItem queryItemWithName:@"connectionSerial" value:serial];
            queryItems = [queryItems arrayByAddingObject:connectionSerialParam];
        }
        else {
            [self.logger error:@"R:%p WS:%p ARTWebSocketTransport: recovery string is malformed, ignoring: '%@'", _delegate, self, options.recover];
        }
    }
    else if (resumeKey != nil && connectionSerial != nil) {
        NSURLQueryItem *resumeKeyParam = [NSURLQueryItem queryItemWithName:@"resume" value:resumeKey];
        queryItems = [queryItems arrayByAddingObject:resumeKeyParam];

        NSURLQueryItem *connectionSerialParam = [NSURLQueryItem queryItemWithName:@"connectionSerial" value:[NSString stringWithFormat:@"%lld", (long long)[connectionSerial integerValue]]];
        queryItems = [queryItems arrayByAddingObject:connectionSerialParam];
    }

    NSURLQueryItem *versionParam = [NSURLQueryItem queryItemWithName:@"v" value:[ARTDefault version]];
    queryItems = [queryItems arrayByAddingObject:versionParam];
    
    // Lib
    NSURLQueryItem *libParam = [NSURLQueryItem queryItemWithName:@"lib" value:[ARTDefault libraryVersion]];
    queryItems = [queryItems arrayByAddingObject:libParam];

    // URL
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:@"/"];
    urlComponents.queryItems = queryItems;
    NSURL *url = [urlComponents URLRelativeToURL:[options realtimeUrl]];

    [_logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p url %@", _delegate, self, url];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    self.websocket = [[SRWebSocket alloc] initWithURLRequest:request];
    self.websocket.delegate = self;
    self.websocketURL = url;
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
    [self.websocket closeWithCode:ARTWsCloseNormal reason:@"Normal Closure"];
    self.websocket = nil;
}

- (void)abort:(ARTStatus *)reason {
    if (!_websocket) return;
    self.websocket.delegate = nil;
    if (reason.errorInfo) {
        [self.websocket closeWithCode:ARTWsAbnormalClose reason:reason.errorInfo.description];
    }
    else {
        [self.websocket closeWithCode:ARTWsAbnormalClose reason:@"Abnormal Closure"];
    }
    self.websocket = nil;
}

- (void)setHost:(NSString *)host {
    self.options.realtimeHost = host;
}

- (NSString *)host {
    return self.options.realtimeHost;
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)websocket {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p websocket did open", _delegate, self];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s.delegate realtimeTransportAvailable:s];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p websocket did disconnect (code %ld) %@", _delegate, self, (long)code, reason];

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
                [s.delegate realtimeTransportFailed:s withError:[[ARTRealtimeTransportError alloc] initWithError:[ARTErrorInfo createWithCode:code message:reason]
                                                                                                            type:ARTRealtimeTransportErrorTypeOther
                                                                                                             url:self.websocketURL]];
                break;
            default:
                NSAssert(true, @"WebSocket close: unknown code");
                break;
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p websocket did receive error %@", _delegate, self, error];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s.delegate realtimeTransportFailed:s withError:[self classifyError:error]];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (ARTRealtimeTransportError *)classifyError:(NSError *)error {
    ARTRealtimeTransportErrorType type = ARTRealtimeTransportErrorTypeOther;

    if ([error.domain isEqualToString:@"com.squareup.SocketRocket"] && error.code == 504) {
        type = ARTRealtimeTransportErrorTypeTimeout;
    } else if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork]) {
        type = ARTRealtimeTransportErrorTypeHostUnreachable;
    } else if ([error.domain isEqualToString:@"NSPOSIXErrorDomain"] && error.code == 57) {
        type = ARTRealtimeTransportErrorTypeNoInternet;
    } else if ([error.domain isEqualToString:SRWebSocketErrorDomain] && error.code == 2132) {
        id status = error.userInfo[SRHTTPResponseErrorKey];
        if (status) {
            return [[ARTRealtimeTransportError alloc] initWithError:error
                                                    badResponseCode:[(NSNumber *)status integerValue]
                                                                url:self.websocketURL];
        }
    }

    return [[ARTRealtimeTransportError alloc] initWithError:error type:type url:self.websocketURL];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    if ([message isKindOfClass:[NSString class]]) {
        [self webSocketMessageText:(NSString *)message];
    } else if ([message isKindOfClass:[NSData class]]) {
        [self webSocketMessageData:(NSData *)message];
    }
}

- (void)webSocketMessageText:(NSString *)text {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p websocket did receive message %@", _delegate, self, text];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        NSData *data = nil;
        data = [((NSString *)text) dataUsingEncoding:NSUTF8StringEncoding];

        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s receiveWithData:data];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketMessageData:(NSData *)data {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p WS:%p websocket did receive data %@", _delegate, self, data];

    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s receiveWithData:data];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

@end
