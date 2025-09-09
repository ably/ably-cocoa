import Foundation

// swift-migration: original location NSURL+ARTUtils.h, line 5 and NSURL+ARTUtils.m, line 3
internal extension URL {
    
    // swift-migration: original location NSURL+ARTUtils.h, line 7 and NSURL+ARTUtils.m, line 5
    static func copyFromURL(_ url: URL, withHost host: String) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.host = host
        return components.url
    }
}