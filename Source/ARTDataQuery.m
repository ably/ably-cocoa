//
//  ARTDataQuery.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTDataQuery+Private.h"
#import "ARTRealtimeChannel+Private.h"

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
        [items addObject:[NSURLQueryItem queryItemWithName:@"start" value:[NSString stringWithFormat:@"%llu", dateToMilliseconds(self.start)]]];
    }
    if (self.end) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"end" value:[NSString stringWithFormat:@"%llu", dateToMilliseconds(self.end)]]];
    }

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%hu", self.limit]]];
    [items addObject:[NSURLQueryItem queryItemWithName:@"direction" value:queryDirectionToString(self.direction)]];

    return items;
}

@end

@implementation ARTRealtimeHistoryQuery

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [super asQueryItems];
    if (self.untilAttach) {
        NSAssert(self.realtimeChannel, @"ARTRealtimeHistoryQuery used from outside ARTRealtimeChannel.history");
        if (self.realtimeChannel.state != ARTRealtimeChannelAttached) {
            @throw [NSError errorWithDomain:ARTAblyErrorDomain code:ARTRealtimeHistoryErrorNotAttached userInfo:nil];
        }
        [items addObject:[NSURLQueryItem queryItemWithName:@"fromSerial" value:self.realtimeChannel.attachSerial]];
    }
    return items;
}

@end
