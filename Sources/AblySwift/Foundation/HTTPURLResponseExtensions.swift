import Foundation

// MARK: - HTTPURLResponse Extensions

extension HTTPURLResponse {
    /// Extracts Link header information for pagination
    func extractLinks() -> [String: String]? {
        guard let linkHeader = allHeaderFields["Link"] as? String else {
            return nil
        }
        
        // Static regex for parsing links - matches "<url>; rel="relation""
        let pattern = "\\s*<([^>]*)>;\\s*rel=\"([^\"]*)\""
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        var links: [String: String] = [:]
        
        let range = NSRange(location: 0, length: linkHeader.count)
        let matches = regex?.matches(in: linkHeader, options: [], range: range) ?? []
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            
            let linkUrlRange = match.range(at: 1)
            let linkRelRange = match.range(at: 2)
            
            guard let linkUrlNSRange = Range(linkUrlRange, in: linkHeader),
                  let linkRelNSRange = Range(linkRelRange, in: linkHeader) else {
                continue
            }
            
            let linkUrl = String(linkHeader[linkUrlNSRange])
            let linkRels = String(linkHeader[linkRelNSRange])
            
            // Split multiple relations and add each
            let relations = linkRels.components(separatedBy: .whitespaces)
            for relation in relations where !relation.isEmpty {
                links[relation] = linkUrl
            }
        }
        
        return links.isEmpty ? nil : links
    }
}