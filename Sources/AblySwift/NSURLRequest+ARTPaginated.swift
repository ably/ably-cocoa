import Foundation

// swift-migration: original location NSURLRequest+ARTPaginated.h, line 5 and NSURLRequest+ARTPaginated.m, line 3
internal extension URLRequest {
    
    // swift-migration: original location NSURLRequest+ARTPaginated.h, line 7 and NSURLRequest+ARTPaginated.m, line 5
    static func requestWithPath(_ path: String?, relativeTo baseRequest: URLRequest) -> URLRequest? {
        guard let path = path else {
            return nil
        }
        guard let url = URL(string: path, relativeTo: baseRequest.url) else {
            return nil
        }
        return URLRequest(url: url)
    }
}