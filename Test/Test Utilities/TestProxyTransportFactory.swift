import Ably.Private

private class TestProxyTransportWebSocket: ARTSRWebSocket {
    weak var testProxyTransport: TestProxyTransport?

    override func open() {
        guard let testProxyTransport else {
            preconditionFailure("Tried to fetch testProxyTransport but it's already been deallocated")
        }
        if !testProxyTransport.handleWebSocketOpen() {
            super.open()
        }
    }
}

private class TestProxyTransportWebSocketFactory: WebSocketFactory {
    weak var testProxyTransport: TestProxyTransport?

    func createWebSocket(with request: URLRequest, logger: InternalLog?) -> ARTWebSocket {
        let webSocket = TestProxyTransportWebSocket(urlRequest: request, logger: logger)
        webSocket.testProxyTransport = testProxyTransport

        return webSocket
    }
}

class TestProxyTransportFactory: RealtimeTransportFactory {
    // This value will be used by all TestProxyTransportFactory instances created by this factory (including those created before this property is updated).
    var fakeNetworkResponse: FakeNetworkResponse?

    // This value will be used by all TestProxyTransportFactory instances created by this factory (including those created before this property is updated).
    var networkConnectEvent: ((ARTRealtimeTransport, URL) -> Void)?

    func transport(withRest rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, connectionSerial: NSNumber?, logger: InternalLog) -> ARTRealtimeTransport {
        let webSocketFactory = TestProxyTransportWebSocketFactory()

        let testProxyTransport = TestProxyTransport(
            factory: self,
            rest: rest,
            options: options,
            resumeKey: resumeKey,
            connectionSerial: connectionSerial,
            logger: logger,
            webSocketFactory: webSocketFactory
        )

        webSocketFactory.testProxyTransport = testProxyTransport

        return testProxyTransport
    }
}
