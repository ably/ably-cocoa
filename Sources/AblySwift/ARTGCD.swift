import Foundation

// swift-migration: original location ARTGCD.h, line 3 and ARTGCD.m, line 10
public class ARTScheduledBlockHandle: NSObject {
    // swift-migration: original location ARTGCD.m, line 6
    // Lock that implements the equivalent of Objective-C `atomic` for the `block` property
    private let _blockLock = NSLock()
    private var _block: (() -> Void)?
    public var block: (() -> Void)? {
        get { _blockLock.withLock { _block } }
        set { _blockLock.withLock { _block = newValue } }
    }
    
    // swift-migration: original location ARTGCD.m, line 11
    private var _scheduledBlock: DispatchWorkItem?
    
    // swift-migration: original location ARTGCD.h, line 4 and ARTGCD.m, line 14
    public init(delay: TimeInterval, queue: DispatchQueue, block: @escaping () -> Void) {
        super.init()
        
        weak var weakSelf: ARTScheduledBlockHandle? = self
        _scheduledBlock = DispatchWorkItem { [weak weakSelf] in
            var copiedBlock: (() -> Void)? = nil
            if let strongSelf = weakSelf {
                copiedBlock = strongSelf.block
            }
            
            // If our block is non-nil, our scheduled block was still valid by the time this was invoked
            copiedBlock?()
        }
        
        self.block = block
        
        queue.asyncAfter(deadline: .now() + delay, execute: _scheduledBlock!)
    }
    
    // swift-migration: original location ARTGCD.h, line 5 and ARTGCD.m, line 40
    public func cancel() {
        self.block = nil
        _scheduledBlock?.cancel()
    }
    
    // swift-migration: original location ARTGCD.m, line 45
    deinit {
        // Explicitly cancel when we deallocate. This happens implicitly since our scheduled block keeps a weak
        // reference to self, but we want to make sure that the weak reference can be safely accessed, even if
        // we're in the midst of deallocating.
        cancel()
    }
}

// swift-migration: original location ARTGCD.h, line 8 and ARTGCD.m, line 54
public func artDispatchScheduled(_ seconds: TimeInterval, _ queue: DispatchQueue, _ block: @escaping () -> Void) -> ARTScheduledBlockHandle {
    // We don't pass the block directly; instead, we put it in a property, and
    // read it back from the property once the timer fires. This gives us the
    // chance to set the property to nil when cancelling the timer, thus
    // releasing our retain on the block early. dispatch_block_cancel doesn't do
    // this, it retains the block even if you cancel the dispatch until the
    // dispatch time passes. (How this is a good idea escapes me.)
    //
    // From Apple's documentation [1]:
    //
    // > Release of any resources associated with the block object is delayed
    // > until execution of the block object is next attempted (or any execution
    // > already in progress completes).
    //
    // https://developer.apple.com/documentation/dispatch/1431058-dispatch_block_cancel

    return ARTScheduledBlockHandle(delay: seconds, queue: queue, block: block)
}

// swift-migration: original location ARTGCD.h, line 9
public func artDispatchCancel(_ handle: ARTScheduledBlockHandle?) {
    handle?.cancel()
}