@testable import AblySwift
import SocketRocket

class TestProxyTransportFactory: RealtimeTransportFactory {
    // This value will be used by all TestProxyTransportFactory instances created by this factory (including those created before this property is updated).
    var fakeNetworkResponse: FakeNetworkResponse?

    // This value will be used by all TestProxyTransportFactory instances created by this factory (including those created before this property is updated).
    var networkConnectEvent: ((ARTRealtimeTransport, URL) -> Void)?

    var transportCreatedEvent: ((ARTRealtimeTransport) -> Void)?

    func transport(withRest rest: ARTRestInternal, options: ARTClientOptions, resumeKey: String?, logger: InternalLog) -> ARTRealtimeTransport {
        let webSocketFactory = WebSocketFactory()

        let testProxyTransport = TestProxyTransport(
            factory: self,
            rest: rest,
            options: options,
            resumeKey: resumeKey,
            logger: logger,
            webSocketFactory: webSocketFactory
        )

        webSocketFactory.testProxyTransport = testProxyTransport

        transportCreatedEvent?(testProxyTransport)
        
        return testProxyTransport
    }

    private class WebSocketFactory: Ably.WebSocketFactory {
        weak var testProxyTransport: TestProxyTransport?

        func createWebSocket(with request: URLRequest, logger: InternalLog?) -> ARTWebSocket {
            let webSocket = WebSocket(urlRequest: request, logger: logger)
            webSocket.testProxyTransport = testProxyTransport

            return webSocket
        }
    }

    private class WebSocket: ARTSRWebSocket {
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
}
