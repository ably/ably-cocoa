//  Code credit to @mxcl. Based on:
//  https://github.com/mxcl/OMGHTTPURLRQ/blob/a757e2a3043c5f031b23ef8dadf82a97856dbfab/Sources/OMGFormURLEncode.m
//

import Foundation

// swift-migration: original location ARTFormEncode.m, line 7
private func enc(_ input: Any, ignore: String) -> String {
    let allowedSet = NSMutableCharacterSet(charactersIn: ignore)
    allowedSet.formUnion(with: CharacterSet.urlQueryAllowed)
    allowedSet.removeCharacters(in: ":/?&=;+!@#$()',*")
    
    return "\(input)".addingPercentEncoding(withAllowedCharacters: allowedSet as CharacterSet) ?? ""
}

// swift-migration: original location ARTFormEncode.m, line 15
private func enckey(_ input: Any) -> String {
    return enc(input, ignore: "[]")
}

// swift-migration: original location ARTFormEncode.m, line 19
private func encval(_ input: Any) -> String {
    return enc(input, ignore: "")
}

// swift-migration: original location ARTFormEncode.m, line 24
private func createSortDescriptor() -> NSSortDescriptor {
    return NSSortDescriptor(key: "description", ascending: true, selector: #selector(NSString.compare(_:)))
}

// swift-migration: original location ARTFormEncode.m, line 28
private func DoQueryMagic(_ key: String?, _ value: Any) -> [Any] {
    var parts: [Any] = []
    
    // Sort dictionary keys to ensure consistent ordering in query string,
    // which is important when deserializing potentially ambiguous sequences,
    // such as an array of dictionaries
    
    if let dictionary = value as? [String: Any] {
        let sortedKeys = (Array(dictionary.keys) as NSArray).sortedArray(using: [createSortDescriptor()])
        for nestedKey in sortedKeys {
            let recursiveKey: String
            if let key = key {
                recursiveKey = "\(key)[\(nestedKey)]"
            } else {
                recursiveKey = "\(nestedKey)"
            }
            parts.append(contentsOf: DoQueryMagic(recursiveKey, dictionary[nestedKey as! String]!))
        }
    } else if let array = value as? [Any] {
        for nestedValue in array {
            parts.append(contentsOf: DoQueryMagic("\(key!)[]", nestedValue))
        }
    } else if let set = value as? Set<AnyHashable> {
        let sortedArray = (set as NSSet).sortedArray(using: [createSortDescriptor()])
        for obj in sortedArray {
            parts.append(contentsOf: DoQueryMagic(key, obj))
        }
    } else {
        parts.append(contentsOf: [key!, value])
    }
    
    return parts
}

// swift-migration: original location ARTFormEncode.h, line 9 and ARTFormEncode.m, line 54
internal func ARTFormEncode(_ parameters: [String: Any]) -> String {
    if parameters.count == 0 {
        return ""
    }
    
    let queryString = NSMutableString()
    let parts = DoQueryMagic(nil, parameters)
    var enumerator = parts.makeIterator()
    
    while true {
        guard let obj = enumerator.next() else { break }
        guard let nextObj = enumerator.next() else { break }
        queryString.appendFormat("%@=%@&", enckey(obj), encval(nextObj))
    }
    
    if queryString.length > 0 {
        queryString.deleteCharacters(in: NSRange(location: queryString.length - 1, length: 1))
    }
    
    return queryString as String
}