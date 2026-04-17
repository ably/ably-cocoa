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

/**
 When `YES`, `ARTLocalDeviceStorage` log lines include the fetched or
 written value itself. Off by default because persisted values include
 the device secret and the identity token. Initial value is `NO`.
 */
@property (nonatomic) BOOL logLocalDeviceStorageValues;

/**
 When `YES`, the `ARTRestInternal` is wired with a storage implementation
 whose every method raises, and the `device_nosync` / push activation
 entrypoints raise early. Intended for clients that should not
 participate in local-device or push functionality at all (e.g. a
 second Ably client in the same process whose only job is to emit
 diagnostic events, where otherwise whichever client touches the
 shared device first "wins" its logger). Initial value is `NO`.
 */
@property (nonatomic) BOOL disableLocalDevice;

@end

NS_ASSUME_NONNULL_END
