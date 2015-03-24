//
//  ARTRealtime+Test.m
//  ably-ios
//
//  Created by vic on 24/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//


#import "ARTRealtime+Test.h"
#import "ARTRealtime.h"
@implementation ARTRealtime (Test)

-(void) fakeDisconnect
{
    NSLog(@"TODO fake disconnect");
    [self onDisconnected:nil];
}
@end
