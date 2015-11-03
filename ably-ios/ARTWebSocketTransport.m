//
//  ARTWebSocketTransport.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTWebSocketTransport.h"

#import <SocketRocket/SRWebSocket.h>

#import "ARTRest.h"
#import "ARTRest+Private.h"
#import "ARTAuth.h"
#import "ARTProtocolMessage.h"
#import "ARTClientOptions.h"
#import "ARTAuthTokenParams.h"
#import "ARTAuthTokenDetails.h"

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

@interface ARTWebSocketTransport () <SRWebSocketDelegate>

@property (readonly, assign, nonatomic) CFRunLoopRef rl;
@property (readonly, strong, nonatomic) dispatch_queue_t queue;
@property (readwrite, strong, nonatomic) SRWebSocket *websocket;
@property (readwrite, assign, nonatomic) BOOL closing;

// From RestClient
@property (readwrite, strong, nonatomic) id<ARTEncoder> encoder;
@property (readonly, strong, nonatomic) ARTLog *logger;
@property (readonly, strong, nonatomic) ARTAuth *auth;
@property (readonly, strong, nonatomic) ARTClientOptions *options;

@end

@implementation ARTWebSocketTransport

// FIXME: Realtime sould be extending from RestClient
- (instancetype)initWithRest:(ARTRest *)rest options:(ARTClientOptions *)options {
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
    }
    return self;
}

- (void)dealloc {
    self.websocket.delegate = nil;
    self.websocket = nil;
}

- (void)send:(ARTProtocolMessage *)msg {
    [self.logger debug:@"ARTWebSocketTransport: sending %@", msg];
    NSData *data = [self.encoder encodeProtocolMessage:msg];
    [self.websocket send:data];
}

- (void)connect {
    [self.logger debug:@"ARTWebSocketTransport: websocket connect"];
    if ([self.options isBasicAuth]) {
        // Basic
        NSURLQueryItem *keyParam = [NSURLQueryItem queryItemWithName:@"key" value:self.options.key];
        [self setupWebSocket:@[keyParam] withOptions:self.options];
        // Connect
        [self.websocket open];
    }
    else {
        __weak ARTWebSocketTransport *selfWeak = self;
        // Token
        [self.auth authorise:nil options:self.options force:false callback:^(ARTAuthTokenDetails *tokenDetails, NSError *error) {
            ARTWebSocketTransport *selfStrong = selfWeak;
            if (!selfStrong) return;

            if (error) {
                [selfStrong.logger error:@"ARTWebSocketTransport: token auth failed with %@", error.description];
                [selfStrong.delegate realtimeTransportFailed:selfStrong];
                return;
            }

            NSURLQueryItem *accessTokenParam = [NSURLQueryItem queryItemWithName:@"access_token" value:(tokenDetails.token)];
            [selfStrong setupWebSocket:@[accessTokenParam] withOptions:selfStrong.options];
            // Connect
            [selfStrong.websocket open];
        }];
    }
}

- (NSURL *)setupWebSocket:(__GENERIC(NSArray, NSURLQueryItem *) *)params withOptions:(ARTClientOptions *)options {
    NSArray *queryItems = params;

    // ClientID
    if (options.clientId) {
        NSURLQueryItem *clientIdParam = [NSURLQueryItem queryItemWithName:@"client_id" value:options.clientId];
        queryItems = [queryItems arrayByAddingObject:clientIdParam];
    }

    // Echo
    NSURLQueryItem *echoParam = [NSURLQueryItem queryItemWithName:@"echo" value:options.echoMessages ? @"true" : @"false"];
    queryItems = [queryItems arrayByAddingObject:echoParam];

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
    else if (options.resumeKey != nil) {
        NSURLQueryItem *resumeKeyParam = [NSURLQueryItem queryItemWithName:@"resume" value:options.resumeKey];
        queryItems = [queryItems arrayByAddingObject:resumeKeyParam];

        NSURLQueryItem *connectionSerialParam = [NSURLQueryItem queryItemWithName:@"connectionSerial" value:[NSString stringWithFormat:@"%lld", options.connectionSerial]];
        queryItems = [queryItems arrayByAddingObject:connectionSerialParam];
    }

    // URL
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:@"/"];
    urlComponents.queryItems = queryItems;
    NSURL *url = [urlComponents URLRelativeToURL:[options realtimeUrl]];

    [_logger debug:@"ARTWebSocketTransport: url: %@", url];
    self.websocket = [[SRWebSocket alloc] initWithURL:url];
    self.websocket.delegate = self;
    [self.websocket setDelegateDispatchQueue:self.queue];
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

-(void) close {
    [self.websocket close];
}

- (void)abort:(ARTStatus *)reason {
    [self.websocket close];
    // TODO review
    self.websocket.delegate = nil;
}


#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:@"ARTWebSocketTransport: websocket did receive message %@", message];
    
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        NSData *data = nil;

        if ([message isKindOfClass:[NSString class]]) {
            data = [((NSString *)message) dataUsingEncoding:NSUTF8StringEncoding];
        } else if (![message isKindOfClass:[NSData class]]) {
            [_logger error:@"ARTWebSocketTransport: binary data not supported at the moment"];
            return;
        } else {
            data = message;
        }

        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            ARTProtocolMessage *pm = [s.encoder decodeProtocolMessage:data];
            [s.delegate realtimeTransport:s didReceiveMessage:pm];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:@"ARTWebSocketTransport: websocket did open"];
    
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s.delegate realtimeTransportAvailable:s];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger error:@"ARTWebSocketTransport: websocket did fail with error %@", error];
    
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if (s) {
            [s.delegate realtimeTransportFailed:s];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    ARTWebSocketTransport * __weak weakSelf = self;
    [self.logger debug:@"ARTWebSocketTransport: websocket did close with reason %@", reason];
    
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if(!s)
        {
            return;
        }
        switch (code) {
            case ARTWsCloseNormal:
                if (s.closing) {
                    // OK
                    [s.delegate realtimeTransportClosed:s];
                    break;
                }
            case ARTWsNeverConnected:
            {
                [s.delegate realtimeTransportNeverConnected:s];
                break;
            }
            case ARTWsBuggyClose:
            case ARTWsGoingAway:
            case ARTWsAbnormalClose:
            {
                // Connectivity issue
                [s.delegate realtimeTransportDisconnected:s];
                break;
            }
            case ARTWsRefuse:
            case ARTWsPolicyValidation:
            {
                [s.delegate realtimeTransportRefused:s];
                break;
            }
            case ARTWsTooBig:
            {
                [s.delegate realtimeTransportTooBig:s];
                break;
            }
            case ARTWsNoUtf8:
            case ARTWsCloseProtocolError:
            case ARTWsUnexpectedCondition:
            case ARTWsExtension:
            case ARTWsTlsError:
            default:
            {
                // Failed
                // no idea why
                [s.delegate realtimeTransportFailed:s];
                break;
            }
        }
    });
    CFRunLoopWakeUp(self.rl);
}

@end
