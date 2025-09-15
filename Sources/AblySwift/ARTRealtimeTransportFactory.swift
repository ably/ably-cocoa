import Foundation

/**
 A factory for creating an `ARTRealtimeTransport` instance.
 */
// swift-migration: original location ARTRealtimeTransportFactory.h, line 14
public protocol RealtimeTransportFactory {
    func transport(withRest rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, logger: InternalLog) -> ARTRealtimeTransport
}

/**
 The implementation of `ARTRealtimeTransportFactory` that should be used in non-test code.
 */
// swift-migration: original location ARTRealtimeTransportFactory.h, line 27 and ARTRealtimeTransportFactory.m, line 5
public class ARTDefaultRealtimeTransportFactory: NSObject, RealtimeTransportFactory {
    
    // swift-migration: original location ARTRealtimeTransportFactory.m, line 7
    public func transport(withRest rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, logger: InternalLog) -> ARTRealtimeTransport {
        let webSocketFactory: WebSocketFactory = ARTDefaultWebSocketFactory()
        return ARTWebSocketTransport(rest: rest, options: options, resumeKey: resumeKey, logger: logger, webSocketFactory: webSocketFactory)
    }
}
