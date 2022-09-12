#import <Foundation/Foundation.h>

#import <Ably/ARTDataQuery.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Describes the interval unit over which statistics are gathered.
 * END CANONICAL PROCESSED DOCSTRING
 */
typedef NS_ENUM(NSUInteger, ARTStatsGranularity) {
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * Interval unit over which statistics are gathered as minutes.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTStatsGranularityMinute,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * Interval unit over which statistics are gathered as hours.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTStatsGranularityHour,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * Interval unit over which statistics are gathered as days.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTStatsGranularityDay,
    /**
     * BEGIN CANONICAL PROCESSED DOCSTRING
     * Interval unit over which statistics are gathered as months.
     * END CANONICAL PROCESSED DOCSTRING
     */
    ARTStatsGranularityMonth
};

/**
 This object is used for providing parameters into `ARTStats`'s methods with paginated results.
 */
@interface ARTStatsQuery : ARTDataQuery

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * `ARTStatsGranularityMinute`, `ARTStatsGranularityHour`, `ARTStatsGranularityDay` or `ARTStatsGranularityMonth`. Based on the unit selected, the given `start` or `end` times are rounded down to the start of the relevant interval depending on the unit granularity of the query.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (nonatomic, assign) ARTStatsGranularity unit;

@end

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the aggregate counts for messages and data transferred.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTStatsMessageCount : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The count of all messages.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger count;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The total number of bytes transferred for all messages.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains a breakdown of summary stats data for different (channel vs presence) message types.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTStatsMessageTypes : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageCount` object containing the count and byte value of messages and presence messages.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageCount *all;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageCount` object containing the count and byte value of messages.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageCount *messages;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageCount` object containing the count and byte value of presence messages.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains a breakdown of summary stats data for traffic over various transport types.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTStatsMessageTraffic : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for all messages (includes `realtime`, `rest` and `webhook` messages).
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for messages transferred over a realtime transport such as web socket.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *realtime;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for messages transferred over a rest transport such as `ARTRest`.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *rest;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTypes` object containing a breakdown of usage by message type for messages delivered using webhooks.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the aggregate data for usage of a resource in a specific scope.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTStatsResourceCount : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The total number of resources opened of this type.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger opened;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The peak number of resources of this type used for this period.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger peak;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The average number of resources of this type used for this period.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger mean;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The minimum total resources of this type used for this period.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger min;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of resource requests refused within this period.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains a breakdown of summary stats data for different (TLS vs non-TLS) connection types.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTStatsConnectionTypes : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsResourceCount` object containing a breakdown of usage by scope over TLS connections (both TLS and non-TLS).
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *all;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsResourceCount` object containing a breakdown of usage by scope over non-TLS connections.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *plain;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsResourceCount` object containing a breakdown of usage by scope over TLS connections.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains the aggregate counts for requests made.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTStatsRequestCount : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of requests that succeeded.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger succeeded;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of requests that failed.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger failed;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The number of requests that were refused, typically as a result of permissions or a limit being exceeded.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Details the stats on push notifications.
 * END CANONICAL PROCESSED DOCSTRING
 */
@interface ARTStatsPushCount : NSObject

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Total number of delivered push notifications.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger succeeded;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Total number of attempted push notifications which were rejected due to invalid request data.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger invalid;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Total number of attempted push notifications including notifications which were rejected as invalid or failed to publish.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger attempted;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Total number of refused push notifications.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger failed;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Total number of push messages.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, assign, nonatomic) NSUInteger messages;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Total number of direct publishes.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Contains application statistics for a specified time interval and time period.
 * END CANONICAL PROCESSED DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING # useful?
 * ARTStats object represents an application’s statistics for the specified interval and time period. Ably aggregates statistics globally for all accounts and applications, and makes these available both through our statistics API as well as your application dashboard.
 * END LEGACY DOCSTRING
 */
@interface ARTStats : NSObject

/// :nodoc:
+ (NSDate *)dateFromIntervalId:(NSString *)intervalId;

/// :nodoc:
+ (ARTStatsGranularity)granularityFromIntervalId:(NSString *)intervalId;

/// :nodoc:
+ (NSString *)toIntervalId:(NSDate *)time granularity:(ARTStatsGranularity)granularity;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTypes` object containing the aggregate count of all message stats.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTraffic` object containing the aggregate count of inbound message stats.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *inbound;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTraffic` object containing the aggregate count of outbound message stats.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *outbound;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsMessageTypes` object containing the aggregate count of persisted message stats.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *persisted;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsConnectionTypes` object containing a breakdown of connection related stats, such as min, mean and peak connections.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsConnectionTypes *connections;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsResourceCount` object containing a breakdown of channels.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *channels;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsRequestCount` object containing a breakdown of API Requests.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsRequestCount *apiRequests;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsRequestCount` object containing a breakdown of Ably Token requests.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsRequestCount *tokenRequests;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * A `ARTStatsPushCount` object containing a breakdown of stats on push notifications.
 * END CANONICAL PROCESSED DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsPushCount *pushes;

/// :nodoc: TODO: docstring
@property (readonly, strong, nonatomic) NSString *inProgress;

/// :nodoc: TODO: docstring
@property (readonly, assign, nonatomic) NSUInteger count;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * The UTC time at which the time period covered begins. If `unit` is set to `minute` this will be in the format `YYYY-mm-dd:HH:MM`, if `hour` it will be `YYYY-mm-dd:HH`, if `day` it will be `YYYY-mm-dd:00` and if `month` it will be `YYYY-mm-01:00`.
 * END CANONICAL PROCESSED DOCSTRING
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
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * Represents the `intervalId` as a `NSDate` object.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (NSDate *)intervalTime;

/**
 * BEGIN CANONICAL PROCESSED DOCSTRING
 * DEPRECATED: this property is deprecated and will be removed in a future version. An alias for `unit` that must be from the unit property of the JSON.
 * END CANONICAL PROCESSED DOCSTRING
 */
- (ARTStatsGranularity)intervalGranularity;

/// :nodoc:
- (NSDate *)dateFromInProgress;

@end

NS_ASSUME_NONNULL_END
