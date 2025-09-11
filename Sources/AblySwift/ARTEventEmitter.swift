import Foundation

// MARK: - NSMutableArray Extension

extension NSMutableArray {
    // swift-migration: original location ARTEventEmitter.m, line 11
    @objc func artRemoveWhere(_ condition: (Any) -> Bool) {
        var length = self.count
        var i = 0
        while i < length {
            if condition(self.object(at: i)) {
                self.removeObject(at: i)
                i -= 1
                length -= 1
            }
            i += 1
        }
    }
}

// MARK: - ARTEventIdentification Protocol

// swift-migration: original location ARTEventEmitter.h, line 9
public protocol ARTEventIdentification {
    func identification() -> String
}

// Protocol to avoid circular reference issues with ARTEventListener
public protocol ARTEventEmitterProtocol: AnyObject {
    var queue: DispatchQueue { get }
    var userQueue: DispatchQueue? { get }
    func off(_ listener: ARTEventListener)
}

// MARK: - ARTEvent

// swift-migration: original location ARTEventEmitter.h, line 16 and ARTEventEmitter.m, line 26
public class ARTEvent: NSObject, ARTEventIdentification {
    private let _value: String
    
    // swift-migration: original location ARTEventEmitter.h, line 18 and ARTEventEmitter.m, line 30
    public init(string value: String) {
        self._value = value
        super.init()
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 19 and ARTEventEmitter.m, line 37
    public class func newWithString(_ value: String) -> ARTEvent {
        return ARTEvent(string: value)
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h - protocol method and ARTEventEmitter.m, line 41
    public func identification() -> String {
        return _value
    }
}

// MARK: - ARTEventListener

// swift-migration: original location ARTEventEmitter.h, line 27 and ARTEventEmitter.m, line 55
public class ARTEventListener: NSObject {
    // swift-migration: original location ARTEventEmitter+Private.h, line 10
    public let eventId: String
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 11 and ARTEventEmitter.m, line 100
    public private(set) var count: Int = 0
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 12
    public private(set) var observer: NSObjectProtocol?
    
    private let _center: NotificationCenter
    private weak var _eventHandler: (any ARTEventEmitterProtocol)? // weak because eventEmitter owns self
    private var _timeoutDeadline: TimeInterval
    private var _timeoutBlock: (() -> Void)?
    private var _work: ARTScheduledBlockHandle?
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 50
    public private(set) var invalidated: Bool = false
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 51  
    public private(set) var timerIsRunning: Bool = false
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 52
    public var hasTimer: Bool {
        return _timeoutBlock != nil
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 15 and ARTEventEmitter.m, line 63
    internal init(id eventId: String, observer: NSObjectProtocol, handler eventHandler: any ARTEventEmitterProtocol, center: NotificationCenter) {
        self.eventId = eventId
        self.observer = observer
        self._center = center
        self._eventHandler = eventHandler
        self._timeoutDeadline = 0
        self._timeoutBlock = nil
        self.timerIsRunning = false
        self.invalidated = false
        super.init()
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 77
    deinit {
        invalidate()
        if let observer = observer {
            _center.removeObserver(observer)
        }
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 82
    internal func removeObserver() {
        guard let observer = self.observer else {
            return
        }
        invalidate()
        if let eventHandler = _eventHandler, let userQueue = eventHandler.userQueue {
            userQueue.async {
                self._center.removeObserver(observer)
                self.observer = nil
            }
        } else {
            _center.removeObserver(observer)
            self.observer = nil
        }
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 99
    internal func handled() -> Bool {
        count += 1
        return count > 1
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 103
    internal func invalidate() {
        invalidated = true
        stopTimer()
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 17 and ARTEventEmitter.m, line 108
    public func setTimer(_ timeoutDeadline: TimeInterval, onTimeout timeoutBlock: @escaping () -> Void) -> ARTEventListener {
        if _timeoutBlock != nil {
            fatalError("timer is already set")
        }
        _timeoutBlock = timeoutBlock
        _timeoutDeadline = timeoutDeadline
        return self
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 117
    private func timeout() {
        let timeoutBlock = _timeoutBlock
        _eventHandler?.off(self) // removes self as a listener, which clears _timeoutBlock.
        if let timeoutBlock = timeoutBlock {
            timeoutBlock()
        }
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 18 and ARTEventEmitter.m, line 129
    public func startTimer() {
        guard let eventHandler = _eventHandler else {
            return
        }
        if timerIsRunning {
            fatalError("timer is already running")
        }
        timerIsRunning = true
        
        _work = artDispatchScheduled(_timeoutDeadline, eventHandler.queue) { [weak self] in
            self?.timeout()
        }
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 19 and ARTEventEmitter.m, line 144
    public func stopTimer() {
        if let work = _work {
            artDispatchCancel(work)
        }
        timerIsRunning = false
        _timeoutBlock = nil
        _work = nil
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 20 and ARTEventEmitter.m, line 151
    public func restartTimer() {
        if let work = _work {
            artDispatchCancel(work)
        }
        timerIsRunning = false
        startTimer()
    }
}

// MARK: - ARTEventEmitter

// swift-migration: original location ARTEventEmitter.h, line 34 and ARTEventEmitter.m, line 161
public class ARTEventEmitter<EventType: ARTEventIdentification, ItemType>: NSObject, ARTEventEmitterProtocol {
    // swift-migration: original location ARTEventEmitter+Private.h, line 35
    public let notificationCenter: NotificationCenter
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 36
    public let queue: DispatchQueue
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 37
    public let userQueue: DispatchQueue?
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 39
    public let listeners: NSMutableDictionary = NSMutableDictionary()
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 40
    public let anyListeners: NSMutableArray = NSMutableArray()
    
    // swift-migration: original location ARTEventEmitter.m, line 163
    public init(queue: DispatchQueue) {
        self.queue = queue
        self.userQueue = nil
        self.notificationCenter = NotificationCenter()
        super.init()
        resetListeners()
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 168
    public init(queues queue: DispatchQueue, userQueue: DispatchQueue?) {
        self.queue = queue
        self.userQueue = userQueue
        self.notificationCenter = NotificationCenter()
        super.init()
        resetListeners()
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 179
    private func _on(_ event: EventType?, callback: @escaping (ItemType) -> Void) -> ARTEventListener {
        let eventId = event == nil ? "\(ObjectIdentifier(self))" :
                                    "\(ObjectIdentifier(self))-\(event!.identification())"
        
        var listener: ARTEventListener?
        let observer = notificationCenter.addObserver(forName: NSNotification.Name(eventId), object: nil, queue: nil) { [weak self] note in
            guard let listener = listener, !listener.invalidated else { return }
            if listener.hasTimer && !listener.timerIsRunning { return }
            listener.stopTimer()
            if let data = note.object as? ItemType {
                callback(data)
            }
        }
        
        listener = ARTEventListener(id: eventId, observer: observer, handler: self, center: notificationCenter)
        addObject(listener!, toArrayWithKey: event == nil ? nil : eventId)
        return listener!
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 47 and ARTEventEmitter.m, line 194
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public func on(_ event: EventType, callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        return _on(event, callback: actualCallback)
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 198
    private func _once(_ event: EventType?, callback: @escaping (ItemType) -> Void) -> ARTEventListener {
        let eventId = event == nil ? "\(ObjectIdentifier(self))" :
                                    "\(ObjectIdentifier(self))-\(event!.identification())"
        
        var listener: ARTEventListener?
        let observer = notificationCenter.addObserver(forName: NSNotification.Name(eventId), object: nil, queue: nil) { [weak self] note in
            guard let listener = listener, !listener.invalidated else { return }
            if listener.hasTimer && !listener.timerIsRunning { return }
            if listener.handled() { return }
            listener.removeObserver()
            self?.removeObject(listener, fromArrayWithKey: event == nil ? nil : eventId)
            if let data = note.object as? ItemType {
                callback(data)
            }
        }
        
        listener = ARTEventListener(id: eventId, observer: observer, handler: self, center: notificationCenter)
        addObject(listener!, toArrayWithKey: event == nil ? nil : eventId)
        return listener!
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 66 and ARTEventEmitter.m, line 216
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public func once(_ event: EventType, callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        return _once(event, callback: actualCallback)
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 56 and ARTEventEmitter.m, line 220
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public func on(_ callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        return _on(nil, callback: actualCallback)
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 75 and ARTEventEmitter.m, line 224
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public func once(_ callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        return _once(nil, callback: actualCallback)
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 83 and ARTEventEmitter.m, line 228
    public func off(_ event: EventType, listener: ARTEventListener) {
        let eventId = "\(ObjectIdentifier(self))-\(event.identification())"
        if eventId != listener.eventId { return }
        listener.removeObserver()
        if let eventListeners = listeners[listener.eventId] as? NSMutableArray {
            eventListeners.remove(listener)
            if eventListeners.firstObject == nil {
                listeners.removeObject(forKey: listener.eventId)
            }
        }
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 90 and ARTEventEmitter.m, line 238
    public func off(_ listener: ARTEventListener) {
        listener.removeObserver()
        if let eventListeners = listeners[listener.eventId] as? NSMutableArray {
            eventListeners.remove(listener)
        }
        anyListeners.remove(listener)
    }
    
    // swift-migration: Lawrence requested this optional listener method for ARTRealtimeChannel migration
    public func off(_ listener: ARTEventListener?) {
        guard let listener = listener else { return }
        off(listener)
    }
    
    // swift-migration: Lawrence requested this optional listener method for ARTRealtimeChannel migration  
    public func off(_ event: EventType, listener: ARTEventListener?) {
        guard let listener = listener else { return }
        off(event, listener: listener)
    }
    
    // swift-migration: original location ARTEventEmitter.h, line 95 and ARTEventEmitter.m, line 244
    public func off() {
        resetListeners()
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 248
    private func resetListeners() {
        for items in listeners.allValues {
            if let items = items as? [ARTEventListener] {
                for item in items {
                    item.removeObserver()
                }
            }
        }
        listeners.removeAllObjects()
        
        for listener in anyListeners {
            if let listener = listener as? ARTEventListener {
                listener.removeObserver()
            }
        }
        anyListeners.removeAllObjects()
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 33 and ARTEventEmitter.m, line 264
    internal func emit(_ event: EventType?, with data: ItemType?) {
        if let event = event {
            notificationCenter.post(name: NSNotification.Name("\(ObjectIdentifier(self))-\(event.identification())"), object: data)
        }
        notificationCenter.post(name: NSNotification.Name("\(ObjectIdentifier(self))"), object: data)
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 271
    private func addObject(_ obj: Any, toArrayWithKey key: String?) {
        if key == nil {
            anyListeners.add(obj)
        } else {
            var array = listeners.object(forKey: key!) as? NSMutableArray
            if array == nil {
                array = NSMutableArray()
                listeners.setObject(array!, forKey: key! as NSString)
            }
            if array!.index(of: obj) == NSNotFound {
                array!.add(obj)
            }
        }
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 287
    private func removeObject(_ obj: Any, fromArrayWithKey key: String?, where condition: ((Any) -> Bool)? = nil) {
        if key == nil {
            anyListeners.remove(obj)
        } else {
            guard let array = listeners.object(forKey: key!) as? NSMutableArray else {
                return
            }
            if let condition = condition {
                array.artRemoveWhere(condition)
            } else {
                array.remove(obj)
            }
            if array.count == 0 {
                listeners.removeObject(forKey: key! as NSString)
            }
        }
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 307
    private func removeObject(_ obj: Any, fromArrayWithKey key: String?) {
        removeObject(obj, fromArrayWithKey: key, where: nil)
    }
}

// MARK: - ARTPublicEventEmitter

// swift-migration: original location ARTEventEmitter+Private.h, line 44 and ARTEventEmitter.m, line 313
public class ARTPublicEventEmitter<EventType: ARTEventIdentification, ItemType>: ARTEventEmitter<EventType, ItemType> {
    private weak var _rest: ARTRestInternal? // weak because rest owns self
    private let _queue: DispatchQueue
    private let _userQueue: DispatchQueue?
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 46 and ARTEventEmitter.m, line 319
    public init(rest: ARTRestInternal, logger: ARTInternalLog) {
        self._rest = rest
        self._queue = rest.queue
        self._userQueue = rest.userQueue
        super.init(queue: rest.queue)
        
        if logger.logLevel == .verbose {
            notificationCenter.addObserver(forName: nil, object: nil, queue: nil) { notification in
                ARTLogVerbose(logger, "PublicEventEmitter Notification emitted \(notification.name)")
            }
        }
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 337
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 341
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public override func on(_ event: EventType, callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        let modifiedCallback: (ItemType) -> Void = { [weak self] value in
            self?._userQueue?.async {
                actualCallback(value)
            }
        }
        
        var listener: ARTEventListener!
        queue.sync {
            listener = super.on(event, callback: modifiedCallback)
        }
        return listener
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 358
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public override func on(_ callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        let modifiedCallback: (ItemType) -> Void = { [weak self] value in
            self?._userQueue?.async {
                actualCallback(value)
            }
        }
        
        var listener: ARTEventListener!
        queue.sync {
            listener = super.on(modifiedCallback)
        }
        return listener
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 375
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public override func once(_ event: EventType, callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        let modifiedCallback: (ItemType) -> Void = { [weak self] value in
            self?._userQueue?.async {
                actualCallback(value)
            }
        }
        
        var listener: ARTEventListener!
        queue.sync {
            listener = super.once(event, callback: modifiedCallback)
        }
        return listener
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 392
    // swift-migration: Lawrence requested optional callback support for ARTRealtimeChannel migration
    public override func once(_ callback: ((ItemType) -> Void)?) -> ARTEventListener {
        let actualCallback = callback ?? { _ in /* no-op */ }
        let modifiedCallback: (ItemType) -> Void = { [weak self] value in
            self?._userQueue?.async {
                actualCallback(value)
            }
        }
        
        var listener: ARTEventListener!
        queue.sync {
            listener = super.once(modifiedCallback)
        }
        return listener
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 409
    public override func off(_ event: EventType, listener: ARTEventListener) {
        queue.sync {
            super.off(event, listener: listener)
        }
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 415
    public override func off(_ listener: ARTEventListener) {
        queue.sync {
            super.off(listener)
        }
    }
    
    // swift-migration: original location ARTEventEmitter.m, line 421
    public override func off() {
        queue.sync {
            super.off()
        }
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 47 and ARTEventEmitter.m, line 427
    public func off_nosync() {
        super.off()
    }
}

// MARK: - ARTInternalEventEmitter

// swift-migration: original location ARTEventEmitter+Private.h, line 51 and ARTEventEmitter.m, line 433
public class ARTInternalEventEmitter<EventType: ARTEventIdentification, ItemType>: ARTEventEmitter<EventType, ItemType> {
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 53 and ARTEventEmitter.m, line 435
    public override init(queue: DispatchQueue) {
        super.init(queue: queue)
    }
    
    // swift-migration: original location ARTEventEmitter+Private.h, line 54 and ARTEventEmitter.m, line 439
    public override init(queues queue: DispatchQueue, userQueue: DispatchQueue?) {
        super.init(queues: queue, userQueue: userQueue)
    }
}
