import Foundation
import SocketRocket

extension InternalLog: ARTSRInternalLog {}

// TODO these line numbers are now out of sync because I added some stuff to the .m file

// swift-migration: original location ARTWebSocketFactory.h, line 12
/// A factory for creating an `ARTWebSocket` object.
public protocol WebSocketFactory {
    // swift-migration: original location ARTWebSocketFactory.h, line 14
    func createWebSocket(with request: URLRequest, logger: InternalLog?) -> ARTWebSocket
}

// swift-migration: original location ARTWebSocketFactory.h, line 22 and ARTWebSocketFactory.m, line 4
/// The implementation of `ARTWebSocketFactory` that should be used in non-test code.
public class ARTDefaultWebSocketFactory: NSObject, WebSocketFactory {
    
    // swift-migration: original location ARTWebSocketFactory.m, line 6
    public func createWebSocket(with request: URLRequest, logger: InternalLog?) -> ARTWebSocket {
        return ARTSRWebSocket(urlRequest: request, logger: logger)
    }
}
