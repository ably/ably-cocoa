//
//  ARTPresence+Private.h
//  ably
//
//  Created by Toni Cárdenas on 5/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTPresence_Private_h
#define ARTPresence_Private_h

#import "ARTPresence.h"
#import "ARTChannel.h"

@interface ARTPresenceQuery ()

- (__GENERIC(NSMutableArray, NSURLQueryItem *) *)asQueryItems;

@end

@interface ARTPresence ()

@property (readonly, getter=getChannel) ARTChannel *channel;

- (instancetype)initWithChannel:(ARTChannel *)channel;

@end

#endif /* ARTPresence_Private_h */
