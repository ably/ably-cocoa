//
//  ARTFallback.m
//  ably
//
//  Created by vic on 19/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTFallback.h"

#import "ARTDefault.h"
#import "ARTStatus.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"

int (^ARTFallback_getRandomHostIndex)(int count) = ^int(int count) {
    return arc4random() % count;
};

@interface ARTFallback ()

@property (readwrite, strong, nonatomic) NSMutableArray * hosts;

@end

@implementation ARTFallback

- (instancetype)initWithFallbackHosts:(art_nullable __GENERIC(NSArray, NSString *) *)fallbackHosts {
    self = [super init];
    if (self) {
        if (fallbackHosts != nil && fallbackHosts.count == 0) {
            return nil;
        }

        self.hosts = [NSMutableArray array];
        NSMutableArray * hostArray = [[NSMutableArray alloc] initWithArray: fallbackHosts ? fallbackHosts : [ARTDefault fallbackHosts]];
        size_t count = [hostArray count];
        for (int i=0; i <count; i++) {
            int randomIndex = ARTFallback_getRandomHostIndex((int)[hostArray count]);
            [self.hosts addObject:[hostArray objectAtIndex:randomIndex]];
            [hostArray removeObjectAtIndex:randomIndex];
        }
    }
    return self;
}

- (instancetype)init {
    return [self initWithFallbackHosts:nil];
}

- (NSString *)popFallbackHost {
    if([self.hosts count] ==0) {
        return nil;
    }
    NSString *host= [self.hosts lastObject];
    [self.hosts removeLastObject];
    return host;
}

@end
