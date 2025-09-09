import Foundation
import Network

// swift-migration: original location ARTURLSession.h, line 5
internal protocol ARTURLSession: AnyObject {
    var queue: DispatchQueue { get }
    
    init(_ queue: DispatchQueue)
    
    func get(_ request: URLRequest, completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) -> ARTCancellable?
    
    func finishTasksAndInvalidate()
}

// swift-migration: original location ARTURLSessionServerTrust.h, line 8 and ARTURLSessionServerTrust.m, line 10
internal class ARTURLSessionServerTrust: NSObject, URLSessionDelegate, URLSessionTaskDelegate, ARTURLSession {
    
    // swift-migration: original location ARTURLSessionServerTrust.m, line 4
    private var _session: URLSession
    // swift-migration: original location ARTURLSessionServerTrust.m, line 5
    private let _queue: DispatchQueue
    
    // swift-migration: original location ARTURLSessionServerTrust.h, line 7 and ARTURLSessionServerTrust.m, line 22
    internal var queue: DispatchQueue {
        return _queue
    }
    
    // swift-migration: original location ARTURLSessionServerTrust.m, line 12
    required internal init(_ queue: DispatchQueue) {
        _queue = queue
        let config = URLSessionConfiguration.ephemeral
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        // Initialize with a placeholder, will be set properly after super.init()
        _session = URLSession(configuration: config)
        super.init()
        _session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // swift-migration: original location ARTURLSessionServerTrust.m, line 26
    internal func finishTasksAndInvalidate() {
        _session.finishTasksAndInvalidate()
    }
    
    // swift-migration: original location ARTURLSessionServerTrust.m, line 30
    internal func get(_ request: URLRequest, completion: @escaping (HTTPURLResponse?, Data?, Error?) -> Void) -> ARTCancellable? {
        let task = _session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            self._queue.async {
                completion(response as? HTTPURLResponse, data, error)
            }
        }
        task.resume()
        return task
    }
}

// Extension to make URLSessionDataTask conform to ARTCancellable
extension URLSessionDataTask: ARTCancellable {
    // URLSessionDataTask already has a cancel() method, so we don't need to add anything
}