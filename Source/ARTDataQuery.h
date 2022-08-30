#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARTQueryDirection) {
    ARTQueryDirectionForwards,
    ARTQueryDirectionBackwards
};

@interface ARTDataQuery : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The time from which the data items are retrieved.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, nullable) NSDate *start;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The time until the data items are retrieved.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, strong, nullable) NSDate *end;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * An upper limit on the number of the data items returned. The default is 100, and the maximum is 1000.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) uint16_t limit;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The order for which the data is returned in. Valid values are `ARTQueryDirectionBackwards` which orders items from most recent to oldest, or `ARTQueryDirectionForwards` which orders items from oldest to most recent. The default is `ARTQueryDirectionBackwards`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) ARTQueryDirection direction;

@end

@interface ARTRealtimeHistoryQuery : ARTDataQuery

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * When `true`, ensures message history is up until the point of the channel being attached. See [continuous history](https://ably.com/docs/realtime/history#continuous-history) for more info. Requires the `direction` to be `ARTQueryDirectionBackwards`. If the channel is not attached, or if `direction` is set to `ARTQueryDirectionForwards`, this option results in an error.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) BOOL untilAttach;

@end

NS_ASSUME_NONNULL_END
