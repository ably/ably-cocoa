import Foundation

// swift-migration: original location ARTQueuedDealloc.h, line 5 and ARTQueuedDealloc.m, line 3
public class ARTQueuedDealloc: NSObject {
    
    private var _ref: AnyObject?
    private let _queue: DispatchQueue
    
    // swift-migration: original location ARTQueuedDealloc.m, line 8
    public init(ref: AnyObject, queue: DispatchQueue) {
        self._ref = ref
        self._queue = queue
        super.init()
    }
    
    // swift-migration: original location ARTQueuedDealloc.m, line 17
    deinit {
        let ref = _ref
        _queue.async {
            _ = ref // Keep reference alive until this block executes
        }
    }
}