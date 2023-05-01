import Ably.Private

class TestProxyTransportFactory: RealtimeTransportFactory {
    let internalQueue: DispatchQueue

    init(internalQueue: DispatchQueue) {
        self.internalQueue = internalQueue
    }

    // This value will be used by all TestProxyTransportFactory instances created by this factory (including those created before this property is updated).
    var fakeNetworkResponse: FakeNetworkResponse?

    // This value will be used by all TestProxyTransportFactory instances created by this factory (including those created before this property is updated).
    var networkConnectEvent: ((ARTRealtimeTransport, URL) -> Void)?

    func transport(withRest rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, connectionSerial: NSNumber?, logger: InternalLog) -> ARTRealtimeTransport {
        let webSocketFactory = DefaultWebSocketFactory()

        return TestProxyTransport(
            factory: self,
            rest: rest,
            options: options,
            resumeKey: resumeKey,
            connectionSerial: connectionSerial,
            logger: logger,
            webSocketFactory: webSocketFactory,
            internalQueue: internalQueue
        )
    }
}
