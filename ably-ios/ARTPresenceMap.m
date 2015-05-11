//
//  ARTPresenceMap.m
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTPresenceMap.h"


@interface ARTPresenceMap ()

@property (readwrite, strong, atomic) NSMutableSet * residualMembers;
@property (readwrite, strong, atomic) NSMutableDictionary * members; // of the form <NSString * key, : NSArray * artpresencemessages>

@end

@implementation ARTPresenceMap

- (NSArray *)getClient:(NSString *) clientId {
    return nil;
}

- (bool)put:(ARTPresenceMessage *) message {
    return false;
}

- (NSArray *)values {
    return nil;
}

-(bool)remove:(ARTPresenceMessage *) message {
    return false;
}

- (void)startSync {
    
}

- (void)endSync {
    
}


#pragma mark private

- (NSString *)memberKey:(ARTPresenceMessage *) message {
    return [NSString stringWithFormat:@"%@:%@", message.connectionId, message.clientId];
}

@end
