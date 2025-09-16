import Foundation

// swift-migration: original location NSURLRequest+ARTUtils.h, line 5 and NSURLRequest+ARTUtils.m, line 3
internal extension URLRequest {
    
    // swift-migration: original location NSURLRequest+ARTUtils.h, line 12 and NSURLRequest+ARTUtils.m, line 5
    func appendingQueryItem(_ item: URLQueryItem) -> URLRequest {
        guard let components = URLComponents(url: self.url!, resolvingAgainstBaseURL: true) else {
            return self
        }
        
        var mutableComponents = components
        var mutableQueryItems = components.queryItems ?? []
        mutableQueryItems.append(item)
        mutableComponents.queryItems = mutableQueryItems
        
        if let modifiedURL = mutableComponents.url {
            var mutableRequest = self
            mutableRequest.url = modifiedURL
            return mutableRequest
        }
        return self
    }
    
    // swift-migration: original location NSURLRequest+ARTUtils.h, line 11 and NSURLRequest+ARTUtils.m, line 24
    /// Note: this method is using URLComponents to deconstruct URL of this request then it replacing `host` with new one.
    /// If for some reasons new URL constructed by URLComponents is `nil`, old URL is a valid URL for this request.
    func replacingHostWith(_ host: String) -> URLRequest {
        guard let components = URLComponents(url: self.url!, resolvingAgainstBaseURL: true) else {
            return self
        }
        
        var mutableComponents = components
        mutableComponents.host = host
        
        if let modifiedURL = mutableComponents.url {
            var mutableRequest = self
            mutableRequest.url = modifiedURL
            return mutableRequest
        }
        return self
    }
}