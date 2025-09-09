import Foundation

// swift-migration: original location ARTFallback+Private.h, line 5 and ARTFallback.m, line 7
internal let ARTFallback_shuffleArray: (NSMutableArray) -> Void = { array in
    let count = array.count
    for i in stride(from: count, to: 1, by: -1) {
        let randomIndex = Int(arc4random_uniform(UInt32(i)))
        array.exchangeObject(at: i - 1, withObjectAt: randomIndex)
    }
}

// swift-migration: original location ARTFallback.h, line 9 and ARTFallback.m, line 17
internal class ARTFallback: NSObject {
    // swift-migration: original location ARTFallback+Private.h, line 9
    internal var hosts: NSMutableArray
    
    // swift-migration: original location ARTFallback.h, line 14 and ARTFallback.m, line 19
    internal init?(fallbackHosts: [String]?, shuffleArray: @escaping (NSMutableArray) -> Void) {
        guard let fallbackHosts = fallbackHosts, !fallbackHosts.isEmpty else {
            return nil
        }
        
        self.hosts = NSMutableArray(array: fallbackHosts)
        super.init()
        shuffleArray(self.hosts)
    }
    
    // swift-migration: original location ARTFallback.h, line 20 and ARTFallback.m, line 31
    internal func popFallbackHost() -> String? {
        if hosts.count == 0 {
            return nil
        }
        let host = hosts.lastObject as? String
        hosts.removeLastObject()
        return host
    }
    
    // swift-migration: original location ARTFallback.h, line 25 and ARTFallback.m, line 40
    internal func isEmpty() -> Bool {
        return hosts.count == 0
    }
}