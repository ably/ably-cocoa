import Foundation

// swift-migration: original location ARTFallbackHosts.h, line 7 and ARTFallbackHosts.m, line 6
internal class ARTFallbackHosts: NSObject {
    
    // swift-migration: original location ARTFallbackHosts.h, line 9 and ARTFallbackHosts.m, line 8
    internal class func hosts(from options: ARTClientOptions) -> [String]? {
        if let fallbackHosts = options.fallbackHosts {
            return fallbackHosts
        }
        
        // swift-migration: original location ARTFallbackHosts.m, line 15
        if options.fallbackHostsUseDefault {
            return ARTDefault.fallbackHosts()
        }
        
        if options.hasEnvironmentDifferentThanProduction {
            return ARTDefault.fallbackHosts(withEnvironment: options.environment!)
        }
        
        if options.hasCustomRestHost || options.hasCustomRealtimeHost || options.hasCustomPort || options.hasCustomTlsPort {
            return nil
        }
        
        return ARTDefault.fallbackHosts()
    }
}
