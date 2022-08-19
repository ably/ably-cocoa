#import <Foundation/Foundation.h>

#import <Ably/ARTDataQuery.h>

NS_ASSUME_NONNULL_BEGIN

/**
 ARTStatsGranularity is an enum specifying the granularity of a ``ARTStats`` interval.
 */
typedef NS_ENUM(NSUInteger, ARTStatsGranularity) {
    ARTStatsGranularityMinute,
    ARTStatsGranularityHour,
    ARTStatsGranularityDay,
    ARTStatsGranularityMonth
};

@interface ARTStatsQuery : ARTDataQuery

@property (nonatomic, assign) ARTStatsGranularity unit;

@end

@interface ARTStatsMessageCount : NSObject

@property (readonly, assign, nonatomic) NSUInteger count;
@property (readonly, assign, nonatomic) NSUInteger data;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCount:(NSUInteger)count
                         data:(NSUInteger)data;

+ (instancetype)empty;

@end

@interface ARTStatsMessageTypes : NSObject

@property (readonly, strong, nonatomic) ARTStatsMessageCount *all;
@property (readonly, strong, nonatomic) ARTStatsMessageCount *messages;
@property (readonly, strong, nonatomic) ARTStatsMessageCount *presence;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(nullable ARTStatsMessageCount *)all
                   messages:(nullable ARTStatsMessageCount *)messages
                   presence:(nullable ARTStatsMessageCount *)presence;

+ (instancetype)empty;

@end

@interface ARTStatsMessageTraffic : NSObject

@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *realtime;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *rest;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *webhook;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(nullable ARTStatsMessageTypes *)all
                   realtime:(nullable ARTStatsMessageTypes *)realtime
                       rest:(nullable ARTStatsMessageTypes *)rest
                    webhook:(nullable ARTStatsMessageTypes *)webhook;

+ (instancetype)empty;

@end

@interface ARTStatsResourceCount : NSObject

@property (readonly, assign, nonatomic) NSUInteger opened;
@property (readonly, assign, nonatomic) NSUInteger peak;
@property (readonly, assign, nonatomic) NSUInteger mean;
@property (readonly, assign, nonatomic) NSUInteger min;
@property (readonly, assign, nonatomic) NSUInteger refused;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOpened:(NSUInteger)opened
                          peak:(NSUInteger)peak
                          mean:(NSUInteger)mean
                           min:(NSUInteger)min
                       refused:(NSUInteger)refused;

+ (instancetype)empty;

@end

@interface ARTStatsConnectionTypes : NSObject

@property (readonly, strong, nonatomic) ARTStatsResourceCount *all;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *plain;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *tls;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(nullable ARTStatsResourceCount *)all
                      plain:(nullable ARTStatsResourceCount *)plain
                        tls:(nullable ARTStatsResourceCount *)tls;

+ (instancetype)empty;

@end

@interface ARTStatsRequestCount : NSObject

@property (readonly, assign, nonatomic) NSUInteger succeeded;
@property (readonly, assign, nonatomic) NSUInteger failed;
@property (readonly, assign, nonatomic) NSUInteger refused;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithSucceeded:(NSUInteger)succeeded
                           failed:(NSUInteger)failed
                          refused:(NSUInteger)refused;

+ (instancetype)empty;

@end

@interface ARTStatsPushCount : NSObject

@property (readonly, assign, nonatomic) NSUInteger succeeded;
@property (readonly, assign, nonatomic) NSUInteger invalid;
@property (readonly, assign, nonatomic) NSUInteger attempted;
@property (readonly, assign, nonatomic) NSUInteger failed;

@property (readonly, assign, nonatomic) NSUInteger messages;
@property (readonly, assign, nonatomic) NSUInteger direct;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithSucceeded:(NSUInteger)succeeded
                          invalid:(NSUInteger)invalid
                        attempted:(NSUInteger)attempted
                           failed:(NSUInteger)failed
                         messages:(NSUInteger)messages
                           direct:(NSUInteger)direct;

+ (instancetype)empty;

@end

/**
 * BEGIN CANONICAL DOCSTRING
 * Contains application statistics for a specified time interval and time period.
 * END CANONICAL DOCSTRING
 *
 * BEGIN LEGACY DOCSTRING
 * ARTStats object represents an application’s statistics for the specified interval and time period. Ably aggregates statistics globally for all accounts and applications, and makes these available both through our statistics API as well as your application dashboard.
 * END LEGACY DOCSTRING
 */
@interface ARTStats : NSObject

+ (NSDate *)dateFromIntervalId:(NSString *)intervalId;
+ (ARTStatsGranularity)granularityFromIntervalId:(NSString *)intervalId;
+ (NSString *)toIntervalId:(NSDate *)time granularity:(ARTStatsGranularity)granularity;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Stats.MessageTypes`]{@link Stats.MessageTypes} object containing the aggregate count of all message stats.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Stats.MessageTraffic`]{@link Stats.MessageTraffic} object containing the aggregate count of inbound message stats.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *inbound;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Stats.MessageTraffic`]{@link Stats.MessageTraffic} object containing the aggregate count of outbound message stats.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *outbound;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Stats.MessageTypes`]{@link Stats.MessageTypes} object containing the aggregate count of persisted message stats.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *persisted;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Stats.ConnectionTypes`]{@link Stats.ConnectionTypes} object containing a breakdown of connection related stats, such as min, mean and peak connections.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsConnectionTypes *connections;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Stats.ResourceCount`]{@link Stats.ResourceCount} object containing a breakdown of channels.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsResourceCount *channels;

/**
 * BEGIN CANONICAL DOCSTRING
 * A [`Stats.RequestCount`]{@link Stats.RequestCount} object containing a breakdown of API Requests.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) ARTStatsRequestCount *apiRequests;
@property (readonly, strong, nonatomic) ARTStatsRequestCount *tokenRequests;
@property (readonly, strong, nonatomic) ARTStatsPushCount *pushes;
@property (readonly, strong, nonatomic) NSString *inProgress;
@property (readonly, assign, nonatomic) NSUInteger count;

/**
 * BEGIN CANONICAL DOCSTRING
 * The UTC time at which the time period covered begins. If `unit` is set to `minute` this will be in the format `YYYY-mm-dd:HH:MM`, if `hour` it will be `YYYY-mm-dd:HH`, if `day` it will be `YYYY-mm-dd:00` and if `month` it will be `YYYY-mm-01:00`.
 * END CANONICAL DOCSTRING
 */
@property (readonly, strong, nonatomic) NSString *intervalId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
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
 * BEGIN CANONICAL DOCSTRING
 * Represents the `intervalId` as a time object.
 * END CANONICAL DOCSTRING
 */
- (NSDate *)intervalTime;

/**
 * BEGIN CANONICAL DOCSTRING
 * DEPRECATED: this property is deprecated and will be removed in a future version. An alias for `unit` that must be from the unit property of the JSON.
 * END CANONICAL DOCSTRING
 */
- (ARTStatsGranularity)intervalGranularity;
- (NSDate *)dateFromInProgress;

@end

NS_ASSUME_NONNULL_END
