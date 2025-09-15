import Foundation

// swift-migration: original location ARTReachability.h, line 7
internal protocol ARTReachability: NSObjectProtocol {
    // swift-migration: original location ARTReachability.h, line 9
    init(logger: InternalLog, queue: DispatchQueue)
    
    // swift-migration: original location ARTReachability.h, line 11
    func listenForHost(_ host: String, callback: @escaping (Bool) -> Void)
    
    // swift-migration: original location ARTReachability.h, line 12
    func off()
}
