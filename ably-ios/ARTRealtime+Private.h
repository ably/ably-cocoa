//
//  ARTRealtime+Private.h
//  ably-ios
//
//  Created by vic on 24/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTProtocolMessage;
@interface ARTRealtime (Privates)
{
    
}


// Transport Events
- (void)onHeartbeat:(ARTProtocolMessage *)message;
- (void)onConnected:(ARTProtocolMessage *)message;
- (void)onDisconnected:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)message;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message;
@end
