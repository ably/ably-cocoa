@import Foundation;

@protocol ARTRealtimeTransportFactory;
@protocol ARTJitterCoefficientGenerator;

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
 Initial value is an instance of `ARTDefaultRealtimeTransportFactory`.
 */
@property (nonatomic) id<ARTRealtimeTransportFactory> transportFactory;

/**
 RTN20c helper.
 This property is used to provide a way for the test code to simulate the case where a reconnection attempt results in a different outcome to the original connection attempt. Initial value is `nil`.
 */
@property (readwrite, nonatomic) NSString *reconnectionRealtimeHost;

/**
 Initial value is an instance of `ARTDefaultJitterCoefficientGenerator`.
 */
@property (nonatomic) id<ARTJitterCoefficientGenerator> jitterCoefficientGenerator;

@end

NS_ASSUME_NONNULL_END
