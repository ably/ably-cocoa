import Ably.Private

class TestProxyTransportFactory: RealtimeTransportFactory {
    func transport(withRest rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, connectionSerial: NSNumber?, logger: InternalLog) -> ARTRealtimeTransport {
        return TestProxyTransport(
            rest: rest,
            options: options,
            resumeKey: resumeKey,
            connectionSerial: connectionSerial,
            logger: logger
        )
    }
}
