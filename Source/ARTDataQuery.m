#import "ARTDataQuery+Private.h"
#import "ARTRealtimeChannel+Private.h"

@implementation ARTDataQuery {
    NSDate *_start;
    NSDate *_end;
    uint16_t _limit;
    ARTQueryDirection _direction;
}

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

- (NSMutableArray *)asQueryItems:(NSError *_Nullable*)error {
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

- (NSDate *)start {
    return _start;
}

- (void)setStart:(NSDate *)value {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change query after you've passed it to the receiver.", self.class]
                                     userInfo:nil];
    }
    _start = value;
}

- (NSDate *)end {
    return _end;
}

- (void)setEnd:(NSDate *)value {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change query after you've passed it to the receiver.", self.class]
                                     userInfo:nil];
    }
    _end = value;
}

- (uint16_t)limit {
    return _limit;
}

- (void)setLimit:(uint16_t)value {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change query after you've passed it to the receiver.", self.class]
                                     userInfo:nil];
    }
    _limit = value;
}

- (ARTQueryDirection)direction {
    return _direction;
}

- (void)setDirection:(ARTQueryDirection)value {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change query after you've passed it to the receiver.", self.class]
                                     userInfo:nil];
    }
    _direction = value;
}

@end

@implementation ARTRealtimeHistoryQuery {
    BOOL _untilAttach;
}

- (NSMutableArray *)asQueryItems:(NSError **)errorPtr {
    NSMutableArray *items = [super asQueryItems:errorPtr];
    if (*errorPtr) {
        return nil;
    }
    if (self.untilAttach) {
        NSAssert(self.realtimeChannel, @"ARTRealtimeHistoryQuery used from outside ARTRealtimeChannel.history");
        if (self.realtimeChannel.state_nosync != ARTRealtimeChannelAttached) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain code:ARTRealtimeHistoryErrorNotAttached userInfo:@{NSLocalizedDescriptionKey:@"ARTRealtimeHistoryQuery: untilAttach used in channel that isn't attached"}];
            return nil;
        }
        [items addObject:[NSURLQueryItem queryItemWithName:@"fromSerial" value:self.realtimeChannel.attachSerial]];
    }
    return items;
}

- (BOOL)untilAttach {
    return _untilAttach;
}

- (void)setUntilAttach:(BOOL)value {
    if (self.isFrozen) {
        @throw [NSException exceptionWithName:NSObjectInaccessibleException
                                       reason:[NSString stringWithFormat:@"%@: You can't change query after you've passed it to the receiver.", self.class]
                                     userInfo:nil];
    }
    _untilAttach = value;
}

@end
