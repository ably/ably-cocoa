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
            
            /*
             //msgpack not supported yet.
            if(false || options.binary) {
                queryParams[@"format"] = @"msgpack";
            }
            */

            if (!echoMessages) {
                queryParams[@"echo"] = @"false";
            }
            
            if(options.recover) {
                NSArray * parts = [options.recover componentsSeparatedByString:@":"];
                if([parts count] ==2) {
                    NSString * conId = [parts objectAtIndex:0];
                    NSString * key = [parts objectAtIndex:1];
                    queryParams[@"recover"] = conId;
                    queryParams[@"connection_serial"] = key;
                }
            }
            else if(options.resume != nil) {
                queryParams[@"resume"]  =  options.resumeKey;
                queryParams[@"connection_serial"] = options.resume;
                
            }

            // TODO configure resume param

            if (clientId) {
                queryParams[@"client_id"] = clientId;
            }

            NSString *queryString = [sRest formatQueryParams:queryParams];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"wss://%@:%d/?%@", realtimeHost, realtimePort, queryString]];

            NSLog(@"Websocket url: %@", url);
            sSelf.websocket = [[SRWebSocket alloc] initWithURL:url];
            sSelf.websocket.delegate = sSelf;
            [sSelf.websocket setDelegateDispatchQueue:sSelf.q];
            return nil;
        }];
    }
    return self;
}

- (void)dealloc {
    self.websocket.delegate = nil;
    self.websocket = nil;
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
    ARTWebSocketTransport * __weak weakSelf = self;

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

        ARTWebSocketTransport *s = weakSelf;
        if(s)
        {
            ARTProtocolMessage *pm = [s.encoder decodeProtocolMessage:data];
            [s.delegate realtimeTransport:s didReceiveMessage:pm];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    ARTWebSocketTransport * __weak weakSelf = self;
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        if(s)
        {
            [s.delegate realtimeTransportAvailable:s];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    ARTWebSocketTransport * __weak weakSelf = self;
    CFRunLoopPerformBlock(self.rl, kCFRunLoopDefaultMode, ^{
        ARTWebSocketTransport *s = weakSelf;
        
        if(error)
        {
            //TODO maybe some errors become failed, and some become disconnect?
            NSLog(@"websocket did fail with error %@", error);
        }
        if(s)
        {
            [s.delegate realtimeTransportFailed:s];
        }
    });
    CFRunLoopWakeUp(self.rl);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    ARTWebSocketTransport * __weak weakSelf = self;
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
