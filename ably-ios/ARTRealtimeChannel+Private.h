
//
//  ARTRealtimeChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTRealtimeChannel.h"

@interface ARTRealtimeChannel (Private)

- (void)setSuspended:(ARTStatus *)error;
- (void)setFailed:(ARTStatus *)error;
- (void)throwOnDisconnectedOrFailed;

@end
