import Foundation
import Runes


// MARK: - Monads

let arrayToJSONData: NSArray -> NSData? = {
    try? NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.allZeros)
}

let dictionaryToJSONData: NSDictionary -> NSData? = {
    try? NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.allZeros)
}

let arrayToPrettyJSONData: NSArray -> NSData? = {
    try? NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.PrettyPrinted)
}

let dictionaryToPrettyJSONData: NSDictionary -> NSData? = {
    try? NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.PrettyPrinted)
}

let dataToJSONString: NSData -> NSString? = {
    NSString(data: $0, encoding: NSUTF8StringEncoding)
}

let JSONStringToData: String -> NSData? = {
    NSString(string: $0).dataUsingEncoding(NSUTF8StringEncoding)
}

let JSONDataToAny: NSData -> AnyObject? = {
    try? NSJSONSerialization.JSONObjectWithData($0, options: .mutableLeaves)
}

/**
**Monad** – Convert array to JSON
*/
let arrayToJSONString: NSArray -> String? = {
    $0 >>- arrayToJSONData >>- dataToJSONString >>- { $0 as String }
}

/**
**Monad** – Convert JSON to dictionary
*/
let JSONToDictionary: NSData -> NSDictionary? = {
    $0 >>- JSONDataToAny >>- { $0 as? NSDictionary ?? nil }
}

/**
**Monad** – Convert JSON to array
*/
let JSONToArray: NSData -> NSArray? = {
    $0 >>- JSONDataToAny >>- { $0 as? NSArray ?? nil }
}
