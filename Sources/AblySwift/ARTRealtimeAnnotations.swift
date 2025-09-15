import Foundation

// swift-migration: original location ARTRealtimeAnnotations.h, line 12
/**
 The protocol upon which the `ARTRealtimeAnnotations` is implemented.
 */
public protocol ARTRealtimeAnnotationsProtocol {
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 23
    /**
     * Registers a listener that is called each time an `ARTAnnotation` is received on the channel.
     *
     * Note that if you want to receive individual realtime annotations (instead of just the rolled-up summaries), you will need to request the `ARTChannelModeAnnotationSubscribe`  in `ARTChannelOptions`, since they are not delivered by default. In general, most clients will not bother with subscribing to individual annotations, and will instead just look at the summary updates.
     *
     * @param callback  A callback containing received annotation.
     *
     * @return An event listener object.
     */
    func subscribe(_ callback: @escaping ARTAnnotationCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 35
    /**
     * Registers a listener that is called each time an `ARTAnnotation` matching a given `type` is received on the channel.
     *
     * Note that if you want to receive individual realtime annotations (instead of just the rolled-up summaries), you will need to request the `ARTChannelModeAnnotationSubscribe` in `ARTChannelOptions`, since they are not delivered by default. In general, most clients will not bother with subscribing to individual annotations, and will instead just look at the summary updates.
     *
     * @param type A type of the `ARTAnnotation` to register the listener for.
     * @param callback  A callback containing received annotation.
     *
     * @return An event listener object.
     */
    func subscribe(_ type: String, callback: @escaping ARTAnnotationCallback) -> ARTEventListener?
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 40
    /**
     * Deregisters all listeners currently receiving `ARTAnnotation` for the channel.
     */
    func unsubscribe()
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 47
    /**
     * Deregisters a specific listener that is registered to receive `ARTAnnotation` on the channel.
     *
     * @param listener An event listener to unsubscribe.
     */
    func unsubscribe(_ listener: ARTEventListener)
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 55
    /**
     * Deregisters a specific listener that is registered to receive `ARTAnnotation` on the channel for a given type.
     *
     * @param type A specific annotation type to deregister the listeners for.
     * @param listener An event listener to unsubscribe.
     */
    func unsubscribe(_ type: String, listener: ARTEventListener)
}

// swift-migration: original location ARTRealtimeAnnotations.h, line 63
/**
 * @see See `ARTRealtimeAnnotationsProtocol` for details.
 */
public class ARTRealtimeAnnotations: NSObject, ARTRealtimeAnnotationsProtocol, @unchecked Sendable {
    
    // swift-migration: original location ARTRealtimeAnnotations+Private.h, line 20 and ARTRealtimeAnnotations.m, line 18
    private let `internal`: ARTRealtimeAnnotationsInternal
    private let _dealloc: ARTQueuedDealloc
    
    // swift-migration: original location ARTRealtimeAnnotations+Private.h, line 22 and ARTRealtimeAnnotations.m, line 22
    internal init(internal: ARTRealtimeAnnotationsInternal, queuedDealloc dealloc: ARTQueuedDealloc) {
        self.`internal` = `internal`
        self._dealloc = dealloc
        super.init()
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 23 and ARTRealtimeAnnotations.m, line 31
    public func subscribe(_ callback: @escaping ARTAnnotationCallback) -> ARTEventListener? {
        return `internal`.subscribe(callback)
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 35 and ARTRealtimeAnnotations.m, line 35
    public func subscribe(_ type: String, callback: @escaping ARTAnnotationCallback) -> ARTEventListener? {
        return `internal`.subscribe(type, callback: callback)
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 40 and ARTRealtimeAnnotations.m, line 39
    public func unsubscribe() {
        `internal`.unsubscribe()
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 47 and ARTRealtimeAnnotations.m, line 43
    public func unsubscribe(_ listener: ARTEventListener) {
        `internal`.unsubscribe(listener)
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 55 and ARTRealtimeAnnotations.m, line 47
    public func unsubscribe(_ type: String, listener: ARTEventListener) {
        `internal`.unsubscribe(type, listener: listener)
    }
}

// swift-migration: original location ARTRealtimeAnnotations+Private.h, line 6
internal class ARTRealtimeAnnotationsInternal: NSObject, ARTRealtimeAnnotationsProtocol {
    
    // swift-migration: original location ARTRealtimeAnnotations+Private.h, line 8 and ARTRealtimeAnnotations.m, line 65
    internal let eventEmitter: ARTEventEmitter<ARTEvent, ARTAnnotation>
    
    // swift-migration: original location ARTRealtimeAnnotations+Private.h, line 14 and ARTRealtimeAnnotations.m, line 64
    internal var queue: DispatchQueue
    
    // swift-migration: original location ARTRealtimeAnnotations.m, line 57
    private let logger: InternalLog
    
    // swift-migration: original location ARTRealtimeAnnotations.m, line 62
    private weak var channel: ARTRealtimeChannelInternal? // weak because channel owns self
    private weak var realtime: ARTRealtimeInternal?
    private let userQueue: DispatchQueue
    private let dataEncoder: ARTDataEncoder
    
    // swift-migration: original location ARTRealtimeAnnotations+Private.h, line 10 and ARTRealtimeAnnotations.m, line 69
    internal init(channel: ARTRealtimeChannelInternal, logger: InternalLog) {
        self.channel = channel
        self.realtime = channel.realtime
        // swift-migration: Lawrence added these two unwraps
        self.userQueue = unwrapValueWithAmbiguousObjectiveCNullability(channel.realtime).rest.userQueue
        self.queue = unwrapValueWithAmbiguousObjectiveCNullability(channel.realtime).rest.queue
        self.logger = logger
        self.eventEmitter = ARTInternalEventEmitter(queue: self.queue)
        self.dataEncoder = channel.dataEncoder
        super.init()
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.m, line 82
    private func _subscribe(_ type: String?, onAttach: ARTCallback?, callback cb: ARTAnnotationCallback?) -> ARTEventListener? {
        var callback = cb
        if let cb = cb {
            let userCallback = cb
            callback = { annotation in
                self.userQueue.async {
                    userCallback(annotation)
                }
            }
        }
        
        var listener: ARTEventListener?
        queue.sync {
            guard let channel = self.channel else { return }
            let options = channel.getOptions_nosync()
            let attachOnSubscribe = options?.attachOnSubscribe ?? true
            if channel.state_nosync == .failed {
                if let onAttach = onAttach, attachOnSubscribe { // RTL7h
                    onAttach(ARTErrorInfo.create(withCode: ARTErrorCode.channelOperationFailedInvalidState.rawValue, message: "attempted to subscribe while channel is in Failed state."))
                }
                ARTLogWarn(self.logger, "R:\(Unmanaged.passUnretained(self.realtime!).toOpaque()) C:\(Unmanaged.passUnretained(channel).toOpaque()) (\(channel.name)) anotation subscribe to '\(type ?? "")' action(s) has been ignored (attempted to subscribe while channel is in FAILED state)")
                return
            }
            if channel.shouldAttach && attachOnSubscribe { // RTP6c
                channel._attach(onAttach)
            }
            listener = type == nil ? self.eventEmitter.on(callback!) : self.eventEmitter.on(ARTEvent.new(withAnnotationType: type!), callback: callback!)
            ARTLogVerbose(self.logger, "R:\(Unmanaged.passUnretained(self.realtime!).toOpaque()) C:\(Unmanaged.passUnretained(channel).toOpaque()) (\(channel.name)) annotation subscribe to '\(type ?? "all")' action(s)")
        }
        return listener
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 23 and ARTRealtimeAnnotations.m, line 112
    internal func subscribe(_ cb: @escaping ARTAnnotationCallback) -> ARTEventListener? {
        return _subscribe(nil, onAttach: nil, callback: cb)
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 35 and ARTRealtimeAnnotations.m, line 116
    internal func subscribe(_ type: String, callback: @escaping ARTAnnotationCallback) -> ARTEventListener? {
        return _subscribe(type, onAttach: nil, callback: callback)
    }
    
    // RTP7
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 40 and ARTRealtimeAnnotations.m, line 122
    internal func unsubscribe() {
        queue.sync {
            _unsubscribe()
            ARTLogVerbose(self.logger, "R:\(Unmanaged.passUnretained(self.realtime!).toOpaque()) C:\(Unmanaged.passUnretained(self.channel!).toOpaque()) (\(self.channel!.name)) annotations unsubscribe to all types")
        }
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.m, line 129
    private func _unsubscribe() {
        eventEmitter.off()
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 47 and ARTRealtimeAnnotations.m, line 133
    internal func unsubscribe(_ listener: ARTEventListener) {
        queue.sync {
            self.eventEmitter.off(listener)
            ARTLogVerbose(self.logger, "R:\(Unmanaged.passUnretained(self.realtime!).toOpaque()) C:\(Unmanaged.passUnretained(self.channel!).toOpaque()) (\(self.channel!.name)) annotations unsubscribe to all types")
        }
    }
    
    // swift-migration: original location ARTRealtimeAnnotations.h, line 55 and ARTRealtimeAnnotations.m, line 140
    internal func unsubscribe(_ type: String, listener: ARTEventListener) {
        queue.sync {
            self.eventEmitter.off(ARTEvent.new(withAnnotationType: type), listener: listener)
            ARTLogVerbose(self.logger, "R:\(Unmanaged.passUnretained(self.realtime!).toOpaque()) C:\(Unmanaged.passUnretained(self.channel!).toOpaque()) (\(self.channel!.name)) annotations unsubscribe to type '\(type)'")
        }
    }
    
    // swift-migration: original location ARTRealtimeAnnotations+Private.h, line 12 and ARTRealtimeAnnotations.m, line 147
    internal func onMessage(_ message: ARTProtocolMessage) {
        for a in message.annotations ?? [] {
            var annotation = a
            if annotation.data != nil {
                do {
                    annotation = try a.decode(with: dataEncoder)
                } catch {
                    let errorInfo = ARTErrorInfo.wrap(ARTErrorInfo.create(withCode: ARTErrorCode.unableToDecodeMessage.rawValue, message: error.localizedDescription), prepend: "Failed to decode data: ")
                    ARTLogError(self.logger, "RT:\(Unmanaged.passUnretained(self.realtime!).toOpaque()) C:\(Unmanaged.passUnretained(self.channel!).toOpaque()) (\(self.channel!.name)) \(errorInfo.message)")
                }
            }
            eventEmitter.emit(ARTEvent.new(withAnnotationType: annotation.type), with: annotation)
        }
    }
}
