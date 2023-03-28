#import <Foundation/Foundation.h>

#import <Ably/ARTDataQuery.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Describes the interval unit over which statistics are gathered.
 */
typedef NS_ENUM(NSUInteger, ARTStatsGranularity) {
    /**
     * Interval unit over which statistics are gathered as minutes.
     */
    ARTStatsGranularityMinute,
    /**
     * Interval unit over which statistics are gathered as hours.
     */
    ARTStatsGranularityHour,
    /**
     * Interval unit over which statistics are gathered as days.
     */
    ARTStatsGranularityDay,
    /**
     * Interval unit over which statistics are gathered as months.
     */
    ARTStatsGranularityMonth
};

/**
 This object is used for providing parameters into `ARTStats`'s methods with paginated results.
 */
@interface ARTStatsQuery : ARTDataQuery

/**
 * `ARTStatsGranularity.ARTStatsGranularityMinute`, `ARTStatsGranularity.ARTStatsGranularityHour`, `ARTStatsGranularity.ARTStatsGranularityDay` or `ARTStatsGranularity.ARTStatsGranularityMonth`. Based on the unit selected, the given `start` or `end` times are rounded down to the start of the relevant interval depending on the unit granularity of the query.
 */
@property (nonatomic, assign) ARTStatsGranularity unit;

@end

/**
 * Contains the aggregate counts for messages and data transferred.
 */
@interface ARTStatsMessageCount : NSObject

/**
 * The count of all messages.
 */
@property (readonly, assign, nonatomic) NSUInteger count;

/**
 * The total number of bytes transferred for all messages.
 */
@property (readonly, assign, nonatomic) NSUInteger data;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithCount:(NSUInteger)count
                         data:(NSUInteger)data;

/// :nodoc:
+ (instancetype)empty;

@end

/**
 * Contains a breakdown of summary stats data for different (channel vs presence) message types.
 */
@interface ARTStatsMessageTypes : NSObject

/**
 * A `ARTStatsMessageCount` object containing the count and byte value of messages and presence messages.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageCount *all;

/**
 * A `ARTStatsMessageCount` object containing the count and byte value of messages.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageCount *messages;

/**
 * A `ARTStatsMessageCount` object containing the count and byte value of presence messages.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageCount *presence;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithAll:(nullable ARTStatsMessageCount *)all
                   messages:(nullable ARTStatsMessageCount *)messages
                   presence:(nullable ARTStatsMessageCount *)presence;

/// :nodoc:
+ (instancetype)empty;

@end

/**
 * Contains a breakdown of summary stats data for traffic over various transport types.
 */
@interface ARTStatsMessageTraffic : NSObject

/**
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for all messages (includes `realtime`, `rest` and `webhook` messages).
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;

/**
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for messages transferred over a realtime transport such as web socket.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *realtime;

/**
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for messages transferred over a rest transport such as `ARTRest`.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *rest;

/**
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for messages delivered using webhooks.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *webhook;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithAll:(nullable ARTStatsMessageTypes *)all
                   realtime:(nullable ARTStatsMessageTypes *)realtime
                       rest:(nullable ARTStatsMessageTypes *)rest
                    webhook:(nullable ARTStatsMessageTypes *)webhook;

/// :nodoc:
+ (instancetype)empty;

@end

/**
 * Contains the aggregate data for usage of a resource in a specific scope.
 */
@interface ARTStatsResourceCount : NSObject

/**
 * The total number of resources opened of this type.
 */
@property (readonly, assign, nonatomic) NSUInteger opened;

/**
 * The peak number of resources of this type used for this period.
 */
@property (readonly, assign, nonatomic) NSUInteger peak;

/**
 * The average number of resources of this type used for this period.
 */
@property (readonly, assign, nonatomic) NSUInteger mean;

/**
 * The minimum total resources of this type used for this period.
 */
@property (readonly, assign, nonatomic) NSUInteger min;

/**
 * The number of resource requests refused within this period.
 */
@property (readonly, assign, nonatomic) NSUInteger refused;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithOpened:(NSUInteger)opened
                          peak:(NSUInteger)peak
                          mean:(NSUInteger)mean
                           min:(NSUInteger)min
                       refused:(NSUInteger)refused;

/// :nodoc:
+ (instancetype)empty;

@end

/**
 * Contains a breakdown of summary stats data for different (`TLS` vs non-`TLS`) connection types.
 */
@interface ARTStatsConnectionTypes : NSObject

/**
 * A `ARTStatsResourceCount` object containing a breakdown of usage by scope over `TLS` connections (both `TLS` and non-`TLS`).
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *all;

/**
 * A `ARTStatsResourceCount` object containing a breakdown of usage by scope over non-`TLS` connections.
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *plain;

/**
 * A `ARTStatsResourceCount` object containing a breakdown of usage by scope over `TLS` connections.
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *tls;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithAll:(nullable ARTStatsResourceCount *)all
                      plain:(nullable ARTStatsResourceCount *)plain
                        tls:(nullable ARTStatsResourceCount *)tls;

/// :nodoc:
+ (instancetype)empty;

@end

/**
 * Contains the aggregate counts for requests made.
 */
@interface ARTStatsRequestCount : NSObject

/**
 * The number of requests that succeeded.
 */
@property (readonly, assign, nonatomic) NSUInteger succeeded;

/**
 * The number of requests that failed.
 */
@property (readonly, assign, nonatomic) NSUInteger failed;

/**
 * The number of requests that were refused, typically as a result of permissions or a limit being exceeded.
 */
@property (readonly, assign, nonatomic) NSUInteger refused;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithSucceeded:(NSUInteger)succeeded
                           failed:(NSUInteger)failed
                          refused:(NSUInteger)refused;

/// :nodoc:
+ (instancetype)empty;

@end

/**
 * Details the stats on push notifications.
 */
@interface ARTStatsPushCount : NSObject

/**
 * Total number of delivered push notifications.
 */
@property (readonly, assign, nonatomic) NSUInteger succeeded;

/**
 * Total number of attempted push notifications which were rejected due to invalid request data.
 */
@property (readonly, assign, nonatomic) NSUInteger invalid;

/**
 * Total number of attempted push notifications including notifications which were rejected as invalid or failed to publish.
 */
@property (readonly, assign, nonatomic) NSUInteger attempted;

/**
 * Total number of refused push notifications.
 */
@property (readonly, assign, nonatomic) NSUInteger failed;

/**
 * Total number of push messages.
 */
@property (readonly, assign, nonatomic) NSUInteger messages;

/**
 * Total number of direct publishes.
 */
@property (readonly, assign, nonatomic) NSUInteger direct;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithSucceeded:(NSUInteger)succeeded
                          invalid:(NSUInteger)invalid
                        attempted:(NSUInteger)attempted
                           failed:(NSUInteger)failed
                         messages:(NSUInteger)messages
                           direct:(NSUInteger)direct;

/// :nodoc:
+ (instancetype)empty;

@end

/**
 * Contains application statistics for a specified time interval and time period.
 */
@interface ARTStats : NSObject

/// :nodoc:
+ (NSDate *)dateFromIntervalId:(NSString *)intervalId;

/// :nodoc:
+ (ARTStatsGranularity)granularityFromIntervalId:(NSString *)intervalId;

/// :nodoc:
+ (NSString *)toIntervalId:(NSDate *)time granularity:(ARTStatsGranularity)granularity;

/**
 * A `ARTStatsMessageTypes` object containing the aggregate count of all message stats.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;

/**
 * A `ARTStatsMessageTraffic` object containing the aggregate count of inbound message stats.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *inbound;

/**
 * A `ARTStatsMessageTraffic` object containing the aggregate count of outbound message stats.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *outbound;

/**
 * A `ARTStatsMessageTypes` object containing the aggregate count of persisted message stats.
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *persisted;

/**
 * A `ARTStatsConnectionTypes` object containing a breakdown of connection related stats, such as min, mean and peak connections.
 */
@property (readonly, strong, nonatomic) ARTStatsConnectionTypes *connections;

/**
 * A `ARTStatsResourceCount` object containing a breakdown of channels.
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *channels;

/**
 * A `ARTStatsRequestCount` object containing a breakdown of API Requests.
 */
@property (readonly, strong, nonatomic) ARTStatsRequestCount *apiRequests;

/**
 * A `ARTStatsRequestCount` object containing a breakdown of Ably Token requests.
 */
@property (readonly, strong, nonatomic) ARTStatsRequestCount *tokenRequests;

/**
 * A `ARTStatsPushCount` object containing a breakdown of stats on push notifications.
 */
@property (readonly, strong, nonatomic) ARTStatsPushCount *pushes;

/// :nodoc: TODO: docstring
@property (readonly, strong, nonatomic) NSString *inProgress;

/// :nodoc: TODO: docstring
@property (readonly, assign, nonatomic) NSUInteger count;

/**
 * The UTC time at which the time period covered begins. If `unit` is set to `minute` this will be in the format `YYYY-mm-dd:HH:MM`, if `hour` it will be `YYYY-mm-dd:HH`, if `day` it will be `YYYY-mm-dd:00` and if `month` it will be `YYYY-mm-01:00`.
 */
@property (readonly, strong, nonatomic) NSString *intervalId;

/// :nodoc:
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// :nodoc:
- (instancetype)initWithAll:(ARTStatsMessageTypes *)all
                    inbound:(ARTStatsMessageTraffic *)inbound
                   outbound:(ARTStatsMessageTraffic *)outbound
                  persisted:(ARTStatsMessageTypes *)persisted
                connections:(ARTStatsConnectionTypes *)connections
                   channels:(ARTStatsResourceCount *)channels
                apiRequests:(ARTStatsRequestCount *)apiRequests
              tokenRequests:(ARTStatsRequestCount *)tokenRequests
                     pushes:(ARTStatsPushCount *)pushes
                 inProgress:(NSString *)inProgress
                      count:(NSUInteger)count
                 intervalId:(NSString *)intervalId;

/**
 * Represents the `intervalId` as a `NSDate` object.
 */
- (NSDate *)intervalTime;

/**
 * DEPRECATED: this property is deprecated and will be removed in a future version. An alias for `unit` that must be from the unit property of the JSON.
 */
- (ARTStatsGranularity)intervalGranularity;

/// :nodoc:
- (NSDate *)dateFromInProgress;

@end

NS_ASSUME_NONNULL_END
