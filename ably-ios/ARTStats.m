//
//  ARTStats.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTStats.h"
#import "ARTDataQuery+Private.h"

@implementation ARTStatsQuery

- (instancetype)init {
    if (self = [super init]) {
        _unit = ARTStatsUnitMinute;
    }

    return self;
}

static NSString *statsUnitToString(ARTStatsUnit unit) {
    switch (unit) {
        case ARTStatsUnitMonth:
            return @"month";
        case ARTStatsUnitDay:
            return @"day";
        case ARTStatsUnitHour:
            return @"hour";
        case ARTStatsUnitMinute:
        default:
            return @"minute";
    }
}

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [super asQueryItems];
    [items addObject:[NSURLQueryItem queryItemWithName:@"unit" value:statsUnitToString(self.unit)]];
    return items;
}

@end

@implementation ARTStatsMessageCount

- (instancetype)initWithCount:(double)count data:(double)data {
    self = [super init];
    if (self) {
        _count = count;
        _data = data;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsMessageCount alloc] initWithCount:0 data:0];
}

@end

@implementation ARTStatsMessageTypes

- (instancetype)initWithAll:(ARTStatsMessageCount *)all messages:(ARTStatsMessageCount *)messages presence:(ARTStatsMessageCount *)presence {
    self = [super init];
    if (self) {
        _all = all;
        _messages = messages;
        _presence = presence;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsMessageTypes alloc] initWithAll:[ARTStatsMessageCount empty]  messages:[ARTStatsMessageCount empty] presence:[ARTStatsMessageCount empty]];
}

@end

@implementation ARTStatsMessageTraffic

- (instancetype)initWithAll:(ARTStatsMessageTypes *)all realtime:(ARTStatsMessageTypes *)realtime rest:(ARTStatsMessageTypes *)rest push:(ARTStatsMessageTypes *)push httpStream:(ARTStatsMessageTypes *)httpStream {
    self = [super init];
    if (self) {
        _all = all;
        _realtime = realtime;
        _rest = rest;
        _push = push;
        _httpStream = httpStream;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsMessageTraffic alloc] initWithAll:[ARTStatsMessageTypes empty] realtime:[ARTStatsMessageTypes empty] rest:[ARTStatsMessageTypes empty] push:[ARTStatsMessageTypes empty] httpStream:[ARTStatsMessageTypes empty]];
}

@end

@implementation ARTStatsResourceCount

- (instancetype)initWithOpened:(double)opened peak:(double)peak mean:(double)mean min:(double)min refused:(double)refused {
    self = [super init];
    if (self) {
        _opened = opened;
        _peak = peak;
        _mean = mean;
        _min = min;
        _refused = refused;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsResourceCount alloc] initWithOpened:0 peak:0 mean:0 min:0 refused:0];
}

@end

@implementation ARTStatsConnectionTypes

- (instancetype)initWithAll:(ARTStatsResourceCount *)all plain:(ARTStatsResourceCount *)plain tls:(ARTStatsResourceCount *)tls {
    self = [super init];
    if (self) {
        _all = all;
        _plain = plain;
        _tls = tls;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsConnectionTypes alloc] initWithAll:[ARTStatsResourceCount empty] plain:[ARTStatsResourceCount empty] tls:[ARTStatsResourceCount empty]];
}

@end

@implementation ARTStatsRequestCount

- (instancetype)initWithSucceeded:(double)succeeded failed:(double)failed refused:(double)refused {
    self = [super init];
    if (self) {
        _succeeded = succeeded;
        _failed = failed;
        _refused = refused;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsRequestCount alloc] initWithSucceeded:0 failed:0 refused:0];
}

@end

@implementation ARTStats

- (instancetype)initWithAll:(ARTStatsMessageTypes *)all inbound:(ARTStatsMessageTraffic *)inbound outbound:(ARTStatsMessageTraffic *)outbound persisted:(ARTStatsMessageTypes *)persisted connections:(ARTStatsConnectionTypes *)connections channels:(ARTStatsResourceCount *)channels apiRequests:(ARTStatsRequestCount *)apiRequests tokenRequests:(ARTStatsRequestCount *)tokenRequests interval:(NSDate *)interval {
    self = [super init];
    if (self) {
        _all = all;
        _inbound = inbound;
        _outbound = outbound;
        _persisted = persisted;
        _connections = connections;
        _channels = channels;
        _apiRequests = apiRequests;
        _tokenRequests = tokenRequests;
        _interval = interval;
    }
    return self;
}

@end
