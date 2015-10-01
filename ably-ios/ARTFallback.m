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

@interface ARTFallback ()

@property (readwrite, strong, nonatomic) NSMutableArray * hosts;

@end

@implementation ARTFallback

- (id)init {
    self = [super init];
    if(self) {
        self.hosts = [NSMutableArray array];
        NSMutableArray * hostArray =[[NSMutableArray alloc] initWithArray: [ARTDefault fallbackHosts]];
        size_t count = [hostArray count];
        for(int i=0; i <count; i++ ) {
            int randomIndex = arc4random() % [hostArray count];
            [self.hosts addObject:[hostArray objectAtIndex:randomIndex]];
            [hostArray removeObjectAtIndex:randomIndex];
        }
    }
    return self;
}

- (NSString *)popFallbackHost {
    if([self.hosts count] ==0) {
        return nil;
    }
    NSString *host= [self.hosts lastObject];
    [self.hosts removeLastObject];
    return host;
}

+ (bool)shouldTryFallback:(ARTHttpResponse *) response  options:(ARTClientOptions *) options {
    if(![options isFallbackPermitted]) {
        return false;
    }
    switch(response.error.statusCode) { //this ably server returned an internal error
        case 500:
        case 501:
        case 502:
        case 503:
        case 504:
            return true;
        default:
            return false;
    }
}

@end
