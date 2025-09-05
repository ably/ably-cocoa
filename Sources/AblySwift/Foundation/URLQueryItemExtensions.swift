import Foundation

// MARK: - URLQueryItem Extensions

extension URLQueryItem {
    /// Creates a URLQueryItem with a stringifiable value
    /// Note: ARTStringifiable protocol will be defined elsewhere
    static func item(withName name: String, stringifiableValue value: Any) -> URLQueryItem {
        // For now, convert to string using description
        let stringValue: String
        if let stringifiable = value as? CustomStringConvertible {
            stringValue = stringifiable.description
        } else {
            stringValue = "\(value)"
        }
        
        return URLQueryItem(name: name, value: stringValue)
    }
}