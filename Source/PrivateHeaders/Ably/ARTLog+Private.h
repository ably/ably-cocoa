#import <Ably/ARTLog.h>

@protocol ARTTimeProvider;

NS_ASSUME_NONNULL_BEGIN

@interface ARTLogLine : NSObject

@property(nonatomic, readonly) NSDate *date;
@property(nonatomic, readonly) ARTLogLevel level;
@property(nonatomic, readonly) NSString *message;

- (instancetype)initWithDate:(NSDate *)date level:(ARTLogLevel)level message:(NSString *)message;

- (NSString *)toString;

@end

@interface ARTLog ()

@property (readonly) NSArray<ARTLogLine *> *captured;
@property (readonly) NSArray<ARTLogLine *> *history;

/**
 The time provider used to stamp `ARTLogLine` entries. Defaults to an `ARTSystemTimeProvider`. Settable so that internal code (or tests) can install an alternative implementation, e.g. to make log line timestamps follow the fake-time clock used elsewhere in the SDK.
 */
@property (nonatomic) id<ARTTimeProvider> timeProvider;

- (instancetype)initCapturingOutput:(BOOL)capturing;
- (instancetype)initCapturingOutput:(BOOL)capturing historyLines:(NSUInteger)historyLines;

@end

NS_ASSUME_NONNULL_END
