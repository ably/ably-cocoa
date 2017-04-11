//
//  ARTWebSocketTransport+Private.h
//  ably
//
//  Created by Ricardo Pereira on 17/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTWebSocketTransport_Private_h
#define ARTWebSocketTransport_Private_h

#import "ARTWebSocketTransport.h"
#import "CompatibilityMacros.h"
#import <SocketRocket/SRWebSocket.h>
#import "ARTEncoder.h"
#import "ARTAuth.h"

ART_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport () <SRWebSocketDelegate>

// From RestClient
@property (readwrite, strong, nonatomic) id<ARTEncoder> encoder;
@property (readonly, strong, nonatomic) ARTLog *logger;
@property (readonly, strong, nonatomic) ARTClientOptions *options;

@property (readwrite, strong, nonatomic, art_nullable) SRWebSocket *websocket;
@property (readwrite, strong, nonatomic, art_nullable) NSURL *websocketURL;

- (NSURL *)setupWebSocket:(__GENERIC(NSArray, NSURLQueryItem *) *)params withOptions:(ARTClientOptions *)options resumeKey:(NSString *__art_nullable)resumeKey connectionSerial:(NSNumber *__art_nullable)connectionSerial;

- (void)setState:(ARTRealtimeTransportState)state;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTWebSocketTransport_Private_h */
