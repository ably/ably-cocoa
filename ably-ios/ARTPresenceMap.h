//
//  ARTPresenceMap.h
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "ARTPresenceMessage.h"
@interface ARTPresenceMap : NSObject
{
    
}






- (NSArray *)getClient:(NSString *) clientId; //returns the current presencestate
- (bool)put:(ARTPresenceMessage *) message;
- (NSArray *)values;
- (bool)remove:(ARTPresenceMessage *) message;
- (void)startSync;
- (void)endSync;
@end
