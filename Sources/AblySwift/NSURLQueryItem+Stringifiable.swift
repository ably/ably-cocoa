import Foundation

// swift-migration: original location NSURLQueryItem+Stringifiable.h, line 6 and NSURLQueryItem+Stringifiable.m, line 4
internal extension URLQueryItem {
    
    // swift-migration: original location NSURLQueryItem+Stringifiable.h, line 8 and NSURLQueryItem+Stringifiable.m, line 6
    static func item(withName name: String, value: ARTStringifiable) -> URLQueryItem {
        return URLQueryItem(name: name, value: value.stringValue())
    }
}