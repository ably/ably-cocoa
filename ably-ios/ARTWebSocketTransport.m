//
//  ARTWebSocketTransport.m
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTWebSocketTransport.h"

#import <SocketRocket/SRWebSocket.h>
#import "ARTOptions.h"
#import "ARTRest.h"
#import "ARTRest+Private.h"

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
@property (readonly, strong, nonatomic) dispatch_queue_t q;
@property (readwrite, strong, nonatomic) SRWebSocket *websocket;
@property (readwrite, assign, nonatomic) BOOL closing;
@property (readwrite, strong, nonatomic) id<ARTEncoder> encoder;


@end

@implementation ARTWebSocketTransport

- (instancetype)initWithRest:(ARTRest *)rest options:(ARTOptions *)options {
    self = [super init];
    if (self) {
        _rl = CFRunLoopGetCurrent();
        _q = dispatch_queue_create("ARTWebSocketTransport", NULL);
        _websocket = nil;
        _closing = NO;
        _encoder = rest.defaultEncoder;

        __weak ARTWebSocketTransport *wSelf = self;
        __weak ARTRest *wRest = rest;

        
        BOOL echoMessages = options.echoMessages;
        NSString *clientId = options.clientId;

        NSString *realtimeHost = options.realtimeHost;
        int realtimePort = options.realtimePort;

        [rest withAuthParams:^id<ARTCancellable>(NSDictionary *authParams) {
            ARTWebSocketTransport *sSelf = wSelf;
            ARTRest *sRest = wRest;

            if (!sSelf || !wRest) {
                return nil;
            }

            NSMutableDictionary *queryParams = [NSMutableDictionary dictionaryWithDictionary:authParams];
            
            
            //TODO thers an echo messages flag as well here.
            
            if(options.binary) {
                queryParams[@"format"] = @"msgpack";
            }
            
            //TODO DELETE
            /*
            if (!binary) {
                queryParams[@"binary"] =@"false"; // We only support json for now
            }
             */

            if (!echoMessages) {
                queryParams[@"echo"] = @"false";
            }

            // TODO configure resume param

            if (clientId) {
                queryParams[@"client_id"] = clientId;
            }

            NSString *queryString = [sRest formatQueryParams:queryParams];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"wss://%@:%d/?%@", realtimeHost, realtimePort, queryString]];

            NSLog(@"Websocket url: %@", url);

            sSelf.websocket = [[SRWebSocket alloc] initWithURL:url];
            sSelf.websocket.delegate = self;
            [sSelf.websocket setDelegateDispatchQueue:sSelf.q];
            return nil;
        }];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"DEALLOC");
}

- (void)send:(ARTProtocolMessage *)msg {
    NSData *data = [self.encoder encodeProtocolMessage:msg];
    [self.websocket send:data];
}

- (void)connect {
    [self.websocket open];
}

- (void)close:(BOOL)sendClose {
    self.closing = YES;
    if (sendClose) {
        ARTProtocolMessage *closeMessage = [[ARTProtocolMessage alloc] init];
        closeMessage.action = ARTProtocolMessageClose;
        [self send:closeMessage];
    }

    [self.websocket close];

    // TODO review
    [self.delegate realtimeTransportClosed:self];
}

- (void)abort:(ARTStatus)reason {
    [self.websocket close];
    // TODO review
    self.websocket.delegate = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"Received message: %@", message);
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        NSData *data = nil;
        if ([message isKindOfClass:[NSString class]]) {
            data = [((NSString *)message) dataUsingEncoding:NSUTF8StringEncoding];

        } else if (![message isKindOfClass:[NSData class]]) {
            // Error
            // TODO log?
            return;
        } else {
            data = message;
        }

        ARTProtocolMessage *pm = [self.encoder decodeProtocolMessage:data];

        [self.delegate realtimeTransport:self didReceiveMessage:pm];
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        [self.delegate realtimeTransportAvailable:self];
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        [self.delegate realtimeTransportUnavailable:self];
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        switch (code) {
            case ARTWsCloseNormal:
                if (self.closing) {
                    // OK
                    [self.delegate realtimeTransportClosed:self];
                    break;
                }
            case ARTWsNeverConnected:
            {
                [self.delegate realtimeTransportNeverConnected:self];
                break;
            }
            case ARTWsBuggyClose:
            case ARTWsGoingAway:
            case ARTWsAbnormalClose:
            {
                // Connectivity issue
                [self.delegate realtimeTransportDisconnected:self];
                break;
            }
            case ARTWsRefuse:
            case ARTWsPolicyValidation:
            {
                [self.delegate realtimeTransportRefused:self];
                break;
            }
            case ARTWsTooBig:
            {
                [self.delegate realtimeTransportTooBig:self];
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
                [self.delegate realtimeTransportFailed:self];
                break;
            }
        }
    });
    CFRunLoopWakeUp(self.rl);
}

@end
