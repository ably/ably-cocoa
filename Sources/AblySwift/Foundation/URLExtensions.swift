import Foundation

// MARK: - URL Extensions

extension URL {
    /// Creates a copy of the URL with a different host
    static func copy(from url: URL, withHost host: String) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.host = host
        return components.url
    }
}

// MARK: - URLRequest Extensions

extension URLRequest {
    /// Creates a mutable request with a path relative to another request
    static func mutableRequest(withPath path: String?, relativeTo request: URLRequest) -> NSMutableURLRequest? {
        guard let path = path else { return nil }
        
        guard let url = URL(string: path, relativeTo: request.url) else {
            return nil
        }
        
        return NSMutableURLRequest(url: url)
    }
}

// MARK: - NSMutableURLRequest Extensions

extension NSMutableURLRequest {
    /// Appends a query item to the URL
    func appendQueryItem(_ item: URLQueryItem) {
        guard let url = self.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        var queryItems = components.queryItems ?? []
        queryItems.append(item)
        components.queryItems = queryItems
        
        if let modifiedURL = components.url {
            self.url = modifiedURL
        }
    }
    
    /// Replaces the host in the URL
    func replaceHost(with host: String) {
        guard let url = self.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        
        components.host = host
        
        if let modifiedURL = components.url {
            self.url = modifiedURL
        }
    }
    
    /// Sets Accept header based on mime types
    func setAcceptHeader(defaultMimeType: String, allMimeTypes: [String]) {
        var mimeTypes = allMimeTypes.filter { $0 != defaultMimeType }
        mimeTypes.insert(defaultMimeType, at: 0)
        
        let accept = mimeTypes.joined(separator: ",")
        setValue(accept, forHTTPHeaderField: "Accept")
    }
}