//
//  ARTPresenceMap.h
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTPresenceMessage;

/// Used to maintain a list of members present on a channel
@interface ARTPresenceMap : NSObject {
    
}

@property (readwrite, nonatomic, assign) int64_t syncSerial;

- (ARTPresenceMessage *)getClient:(NSString *) clientId;
- (void)put:(ARTPresenceMessage *) message;

//of the form <NSString *, ARTPresenceMessage*> where
// the key is the clientId and the value is the latest relevant ARTPresenceMessage for that clientId.
- (NSDictionary *) members;
- (void)startSync;
- (void)endSync;
- (BOOL)isSyncComplete;
- (BOOL) stillSyncing;

typedef void(^VoidCb)();
- (void) syncMessageProcessed;
- (void)onSync:(VoidCb) cb;

@end
