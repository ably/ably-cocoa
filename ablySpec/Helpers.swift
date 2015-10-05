//
//  FunctionHelpers.swift
//  Ably
//
//  Created by Ricardo Pereira on 01/09/2015.
//  Copyright (c) 2015 Ricardo Pereira. All rights reserved.
//

import Foundation
import Runes


// MARK: - Global Functions

/**
**Public function** – Load JSON from a file
*/
func JSONFromFile(fileName: String) -> AnyObject? {
    return NSBundle.mainBundle().pathForResource(fileName, ofType: "json")
        >>- { NSData(contentsOfFile: $0) }
        >>- { NSJSONSerialization.JSONObjectWithData($0, options: NSJSONReadingOptions(0), error: nil) }
}


// MARK: - Monads

let arrayToJSONData: NSArray -> NSData? = {
    NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.allZeros, error: nil)
}

let dictionaryToJSONData: NSDictionary -> NSData? = {
    NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.allZeros, error: nil)
}

let arrayToPrettyJSONData: NSArray -> NSData? = {
    NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
}

let dictionaryToPrettyJSONData: NSDictionary -> NSData? = {
    NSJSONSerialization.dataWithJSONObject($0, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
}

let dataToJSONString: NSData -> NSString? = {
    NSString(data: $0, encoding: NSUTF8StringEncoding)
}

let JSONStringToData: String -> NSData? = {
    NSString(string: $0).dataUsingEncoding(NSUTF8StringEncoding)
}

let JSONDataToAny: NSData -> AnyObject? = {
    NSJSONSerialization.JSONObjectWithData($0, options: .MutableLeaves, error: nil)
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
