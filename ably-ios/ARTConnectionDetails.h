//
//  ARTConnectionDetails.h
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTProtocolMessage;

@interface ARTConnectionDetails : NSObject

@property (readonly, getter=getClientId) NSString *clientId;
@property (readonly, getter=getConnectionKey) NSString *connectionKey;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)protocolMessage;

@end
