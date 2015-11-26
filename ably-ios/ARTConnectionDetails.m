//
//  ARTConnectionDetails.m
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnectionDetails.h"

#import "ARTProtocolMessage.h"

@interface ARTConnectionDetails () {
    // FIXME: temporary
    __weak ARTProtocolMessage* _protocolMessage;
}

@end

@implementation ARTConnectionDetails

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)protocolMessage {
    if (self == [super init]) {
        _protocolMessage = protocolMessage;
    }
    return self;
}

- (NSString *)getClientId {
    return _protocolMessage.clientId;
}

- (NSString *)getConnectionKey {
    return _protocolMessage.connectionKey;
}

@end
