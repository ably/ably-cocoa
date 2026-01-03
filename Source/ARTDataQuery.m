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

- (NSStringDictionary *)asQueryParams {
    NSMutableStringDictionary *items = [NSMutableStringDictionary dictionary];

    if (self.start) {
        items[@"start"] = [NSString stringWithFormat:@"%llu", dateToMilliseconds(self.start)];
    }
    if (self.end) {
        items[@"end"] = [NSString stringWithFormat:@"%llu", dateToMilliseconds(self.end)];
    }
    
    items[@"limit"] = [NSString stringWithFormat:@"%hu", self.limit];
    items[@"direction"] = queryDirectionToString(self.direction);

    return items;
}

@end

@implementation ARTRealtimeHistoryQuery

- (NSStringDictionary *)asQueryParams {
    NSMutableStringDictionary *params = super.asQueryParams.mutableCopy;
    params[@"fromSerial"] = self.realtimeChannelAttachSerial;
    return params;
}

@end
