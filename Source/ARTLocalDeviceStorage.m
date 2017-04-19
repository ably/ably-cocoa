//
//  ARTLocalDeviceStorage.m
//  Ably
//
//  Created by Ricardo Pereira on 18/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTLocalDeviceStorage.h"

@implementation ARTLocalDeviceStorage

- (NSData *)readKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)writeKey:(NSString *)key withValue:(id)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
