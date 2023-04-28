//
//  JSON.swift
//  Ably
//
//  Created by Łukasz Szyszkowski on 14/04/2023.
//  Copyright © 2023 Ably. All rights reserved.
//

import Foundation

final class JSONUtility {
    private let decoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return jsonDecoder
    }()
    
    private let encoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        
        return jsonEncoder
    }()
    
    func decode<T: Codable>(path: String) throws -> T {
        let url = URL(fileURLWithPath: path)
        
        return try decode(url: url)
    }
    
    func decode<T: Codable>(url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        
        return try decode(data: data)
    }
    
    func decode<T: Codable>(data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
    
    func encode(_ model: Encodable) throws -> Data {
        try encoder.encode(model)
    }
    
    func serialize(_ object: Any) throws -> Data {
        if #available(iOS 11.0, *) {
            return try JSONSerialization.data(withJSONObject: object, options: .sortedKeys)
        } else {
            return try JSONSerialization.data(withJSONObject: object)
        }
    }
    
    func toJSONString( _ object: Any, encoding: String.Encoding = .utf8) -> String? {
        guard let data = try? serialize(object) else {
            return nil
        }
        
        return String(bytes: data, encoding: encoding)
    }
    
    func codableToDictionary( _ model: Codable) -> [String: Any]? {
        guard let data = try? encode(model) else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    static func jsonObject<T: Any>(data: Data?) -> T? {
        guard let data else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: data) as? T
    }
}

extension Encodable {
    func rawData() throws -> Data {
        try JSONUtility().encode(self)
    }
}

extension Data {
    init(path: String) throws {
        let url = URL(fileURLWithPath: path)
        try self.init(contentsOf: url)
    }
}
