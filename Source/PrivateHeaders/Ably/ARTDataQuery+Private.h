#import <Ably/ARTDataQuery.h>
#import "ARTRealtimeChannel+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTDataQuery (Private)

- (NSStringDictionary *)asQueryParams;

@end

@interface ARTRealtimeHistoryQuery ()

@property (readwrite, copy) NSString *realtimeChannelAttachSerial;

@end

NS_ASSUME_NONNULL_END
