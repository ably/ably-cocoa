import Foundation

struct CryptoData: Codable {
    let algorithm: String
    let mode: String
    let keylength: Int
    let key: String
    let iv: String
    let items: [Item]
}

/**
 Item
 */
extension CryptoData {
    struct Item: Codable {
        let encoded: Encoded
        let encrypted: Encrypted
        let msgpack: String
    }
}

/**
 Encrypted
 */
extension CryptoData.Item {
    struct Encrypted: Codable {
        let name: String
        let data: String
        let encoding: String
    }
}

/**
 Encoded
 */
extension CryptoData.Item {
    struct Encoded: Codable {
        let name: String
        let data: String
        let encoding: String?
    }
}
