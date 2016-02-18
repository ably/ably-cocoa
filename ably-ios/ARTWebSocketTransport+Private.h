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

@interface ARTWebSocketTransport (Private)

- (void)sendWithData:(NSData *)data;
- (void)receiveWithData:(NSData *)data;

@end

#endif /* ARTWebSocketTransport_Private_h */
