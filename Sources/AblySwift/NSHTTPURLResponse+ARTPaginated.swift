import Foundation

// swift-migration: original location NSHTTPURLResponse+ARTPaginated.h, line 5 and NSHTTPURLResponse+ARTPaginated.m, line 3
internal extension HTTPURLResponse {
    
    // swift-migration: original location NSHTTPURLResponse+ARTPaginated.h, line 7 and NSHTTPURLResponse+ARTPaginated.m, line 5
    func extractLinks() -> [String: String]? {
        guard let linkHeader = allHeaderFields["Link"] as? String else {
            return nil
        }
        
        // swift-migration: Recreate the regex pattern from original
        let linkRegexPattern = "\\s*<([^>]*)>;\\s*rel=\"([^\"]*)\""
        guard let linkRegex = try? NSRegularExpression(pattern: linkRegexPattern, options: []) else {
            return nil
        }
        
        var links: [String: String] = [:]
        
        let matches = linkRegex.matches(in: linkHeader, options: [], range: NSRange(location: 0, length: linkHeader.count))
        for match in matches {
            let linkUrlRange = match.range(at: 1)
            let linkRelRange = match.range(at: 2)
            
            guard let linkUrlSwiftRange = Range(linkUrlRange, in: linkHeader),
                  let linkRelSwiftRange = Range(linkRelRange, in: linkHeader) else {
                continue
            }
            
            let linkUrl = String(linkHeader[linkUrlSwiftRange])
            let linkRels = String(linkHeader[linkRelSwiftRange])
            
            let linkRelComponents = linkRels.components(separatedBy: .whitespaces)
            for linkRel in linkRelComponents {
                links[linkRel] = linkUrl
            }
        }
        
        return links.isEmpty ? nil : links
    }
}