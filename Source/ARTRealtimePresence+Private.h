//
//  ARTRealtimePresence+Private.h
//  ably
//
//  Created by Toni Cárdenas on 7/4/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTRealtimePresence.h>
#import <Ably/ARTRealtimeChannel+Private.h>

@interface ARTRealtimePresence ()

- (instancetype)initWithChannel:(ARTRealtimeChannelInternal *)channel;
- (void)_unsubscribe;
- (BOOL)getSyncComplete_nosync;

@end
