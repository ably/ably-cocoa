@import Foundation;

@protocol ARTLocalDeviceFetcher;

NS_ASSUME_NONNULL_BEGIN

/**
 Provides an interface for injecting additional configuration into `ARTRest` or `ARTRealtime` instances.

 This is for anything that test code wishes to be able to configure but which should not be part of the public API of these classes.
 */
@interface ARTTestClientOptions: NSObject <NSCopying>

/**
 Initial value is `nil`.
 */
@property (nullable, nonatomic, copy) NSString *channelNamePrefix;

/**
 Initial value is `ARTDefault.realtimeRequestTimeout`.
 */
@property (nonatomic) NSTimeInterval realtimeRequestTimeout;

/**
 Initial value is `ARTFallback_shuffleArray`.
 */
@property (nonatomic) void (^shuffleArray)(NSMutableArray *);

/**
 Initial value is `ARTDefaultLocalDeviceFetcher.sharedInstance`.
 */
@property (nonatomic) id<ARTLocalDeviceFetcher> localDeviceFetcher;

@end

NS_ASSUME_NONNULL_END
