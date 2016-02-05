//
//  ARTDataQuery.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTDataQuery+Private.h"

@implementation ARTDataQuery

- (instancetype)init {
    if (self = [super init]) {
        _limit = 100;
        _direction = ARTQueryDirectionBackwards;
    }

    return self;
}

static NSString *queryDirectionToString(ARTQueryDirection direction) {
    switch (direction) {
        case ARTQueryDirectionForwards:
            return @"forwards";
        case ARTQueryDirectionBackwards:
        default:
            return @"backwards";
    }
}

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [NSMutableArray array];

    if (self.start) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"start" value:[NSString stringWithFormat:@"%llu", dateToMiliseconds(self.start)]]];
    }
    if (self.end) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"end" value:[NSString stringWithFormat:@"%llu", dateToMiliseconds(self.end)]]];
    }

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%hu", self.limit]]];
    [items addObject:[NSURLQueryItem queryItemWithName:@"direction" value:queryDirectionToString(self.direction)]];

    return items;
}

@end

@implementation ARTRealtimeHistoryQuery

@end
