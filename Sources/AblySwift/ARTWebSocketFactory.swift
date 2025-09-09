import Foundation
import SocketRocket

// swift-migration: original location ARTWebSocketFactory.h, line 12
/// A factory for creating an `ARTWebSocket` object.
public protocol ARTWebSocketFactory {
    // swift-migration: original location ARTWebSocketFactory.h, line 14
    func createWebSocket(withURLRequest request: URLRequest, logger: ARTInternalLog?) -> ARTWebSocket
}

// swift-migration: original location ARTWebSocketFactory.h, line 22 and ARTWebSocketFactory.m, line 4
/// The implementation of `ARTWebSocketFactory` that should be used in non-test code.
public class ARTDefaultWebSocketFactory: NSObject, ARTWebSocketFactory {
    
    // swift-migration: original location ARTWebSocketFactory.m, line 6
    public func createWebSocket(withURLRequest request: URLRequest, logger: ARTInternalLog?) -> ARTWebSocket {
        return ARTSRWebSocket(urlRequest: request, logger: logger)
    }
}
