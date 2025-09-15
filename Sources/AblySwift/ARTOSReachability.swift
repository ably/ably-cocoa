import Foundation
import SystemConfiguration

// Global typealias for network reachability context retain function  
typealias ARTNetworkReachabilityContextRetain = @convention(c) (UnsafeRawPointer?) -> UnsafeRawPointer?

// Helper class to wrap callback block for Core Foundation bridging
private class ARTReachabilityCallback {
    let callback: (SCNetworkReachabilityFlags) -> Void
    
    init(callback: @escaping (SCNetworkReachabilityFlags) -> Void) {
        self.callback = callback
    }
}

// swift-migration: original location ARTOSReachability.m, line 15
/// Global callback for network state changes
func ARTOSReachability_Callback(target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }
    let callbackWrapper: ARTReachabilityCallback = Unmanaged.fromOpaque(info).takeUnretainedValue()
    callbackWrapper.callback(flags)
}

// swift-migration: original location ARTOSReachability+Private.h, line 3 and ARTOSReachability.m, line 20
internal class ARTOSReachability: NSObject, ARTReachability {
    private let logger: InternalLog
    private var host: String?
    private var reachabilityRef: SCNetworkReachability?
    private let queue: DispatchQueue
    
    // swift-migration: original location ARTOSReachability.m, line 27
    required init(logger: InternalLog, queue: DispatchQueue) {
        self.logger = logger
        self.queue = queue
        super.init()
    }
    
    // swift-migration: original location ARTOSReachability.m, line 35
    internal func listenForHost(_ host: String, callback: @escaping (Bool) -> Void) {
        off()
        self.host = host
        
        // This strategy is taken from Mike Ash's book "The Complete Friday Q&A: Volume III".
        // Article: https://www.mikeash.com/pyblog/friday-qa-2013-06-14-reachability.html
        
        weak var weakSelf = self
        let callbackBlock: (SCNetworkReachabilityFlags) -> Void = { flags in
            guard let strongSelf = weakSelf else { return }
            let reachable = (flags.rawValue & SCNetworkReachabilityFlags.reachable.rawValue) != 0
            ARTLogInfo(strongSelf.logger, "Reachability: host \(strongSelf.host ?? "") is reachable: \(reachable ? "true" : "false")")
            strongSelf.queue.async {
                callback(reachable)
            }
        }
        
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            return
        }
        self.reachabilityRef = reachability
        
        // Create wrapper for the callback
        let callbackWrapper = ARTReachabilityCallback(callback: callbackBlock)
        let unmanagedCallback = Unmanaged.passRetained(callbackWrapper)
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: unmanagedCallback.toOpaque(),
            retain: { info in
                return info
            },
            release: { info in
                let unmanaged = Unmanaged<ARTReachabilityCallback>.fromOpaque(info)
                unmanaged.release()
            },
            copyDescription: nil
        )
        
        if SCNetworkReachabilitySetCallback(reachability, ARTOSReachability_Callback, &context) {
            if SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) {
                ARTLogInfo(logger, "Reachability: started listening for host \(host)")
            } else {
                ARTLogWarn(logger, "Reachability: failed starting listener for host \(host)")
            }
        }
    }
    
    // swift-migration: original location ARTOSReachability.m, line 74
    internal func off() {
        if let reachabilityRef = reachabilityRef {
            ARTLogInfo(logger, "Reachability: stopped listening for host \(host ?? "")")
            SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
            self.reachabilityRef = nil
        }
        host = nil
    }
    
    // swift-migration: original location ARTOSReachability.m, line 85
    deinit {
        off()
    }
}
