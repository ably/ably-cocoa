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
#import <PocketSocket/PSWebSocket.h>

ART_ASSUME_NONNULL_BEGIN

@interface ARTWebSocketTransport ()

@property (readwrite, strong, nonatomic, art_nullable) PSWebSocket *websocket;
@property (readwrite, strong, nonatomic, art_nullable) NSURL *websocketURL;

- (void)sendWithData:(NSData *)data;
- (void)receiveWithData:(NSData *)data;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTWebSocketTransport_Private_h */
