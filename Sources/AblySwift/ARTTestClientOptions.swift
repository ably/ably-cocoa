import Foundation

// swift-migration: original location ARTTestClientOptions.h, line 13
/**
 Provides an interface for injecting additional configuration into `ARTRest` or `ARTRealtime` instances.

 This is for anything that test code wishes to be able to configure but which should not be part of the public API of these classes.
 */
public class ARTTestClientOptions: NSObject, NSCopying {

    // swift-migration: original location ARTTestClientOptions.h, line 18
    /**
     Initial value is `nil`.
     */
    public var channelNamePrefix: String?

    // swift-migration: original location ARTTestClientOptions.h, line 23
    /**
     Initial value is `ARTDefault.realtimeRequestTimeout`.
     */
    public var realtimeRequestTimeout: TimeInterval

    // swift-migration: original location ARTTestClientOptions.h, line 28
    /**
     Initial value is `ARTFallback_shuffleArray`.
     */
    public var shuffleArray: (NSMutableArray) -> Void

    // swift-migration: original location ARTTestClientOptions.h, line 33
    /**
     Initial value is an instance of `ARTDefaultRealtimeTransportFactory`.
     */
    public var transportFactory: ARTRealtimeTransportFactory

    // swift-migration: original location ARTTestClientOptions.h, line 39
    /**
     RTN20c helper.
     This property is used to provide a way for the test code to simulate the case where a reconnection attempt results in a different outcome to the original connection attempt. Initial value is `nil`.
     */
    public var reconnectionRealtimeHost: String?

    // swift-migration: original location ARTTestClientOptions.h, line 44
    /**
     Initial value is an instance of `ARTDefaultJitterCoefficientGenerator`.
     */
    public var jitterCoefficientGenerator: ARTJitterCoefficientGenerator

    // swift-migration: original location ARTTestClientOptions.m, line 9
    public override init() {
        realtimeRequestTimeout = ARTDefault.realtimeRequestTimeout()
        shuffleArray = ARTFallback_shuffleArray
        transportFactory = ARTDefaultRealtimeTransportFactory()
        jitterCoefficientGenerator = ARTDefaultJitterCoefficientGenerator()
        super.init()
    }

    // swift-migration: original location ARTTestClientOptions.m, line 20
    public func copy(with zone: NSZone?) -> Any {
        let copied = ARTTestClientOptions()
        copied.channelNamePrefix = self.channelNamePrefix
        copied.realtimeRequestTimeout = self.realtimeRequestTimeout
        copied.shuffleArray = self.shuffleArray
        copied.transportFactory = self.transportFactory
        copied.reconnectionRealtimeHost = self.reconnectionRealtimeHost
        copied.jitterCoefficientGenerator = self.jitterCoefficientGenerator
        return copied
    }

}