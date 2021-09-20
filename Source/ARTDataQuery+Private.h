//
//  ARTDataQuery+Private.h
//  ably
//
//

#import <Ably/ARTDataQuery.h>
#import <Ably/ARTRealtimeChannel+Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDataQuery(Private)

- (NSMutableArray /* <NSURLQueryItem *> */ *)asQueryItems:(NSError *_Nullable *)error;

@end

@interface ARTRealtimeHistoryQuery ()

@property (strong, readwrite) ARTRealtimeChannelInternal *realtimeChannel;

@end

NS_ASSUME_NONNULL_END
