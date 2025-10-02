import Foundation

struct TestAppSetup: Codable {
    let cipher: Cipher
    let postApps: PostApps
}

/**
 PostApps
 */
extension TestAppSetup {
    struct PostApps: Codable {
        let limits: Limits
        let keys: [Key]
        let namespaces: [Namespace]
        let channels: [Channel]
    }
}

/**
 Limits
 */
extension TestAppSetup.PostApps {
    struct Limits: Codable {
        let presence: Presence
    }
}

/**
 Key
 */
extension TestAppSetup.PostApps {
    struct Key: Codable {
        let capability: String?
    }
}

/**
 Namespace
 */
extension TestAppSetup.PostApps {
    struct Namespace: Codable {
        let id: String
        let persisted: Bool?
        let pushEnabled: Bool?
    }
}

/**
 Channel
 */
extension TestAppSetup.PostApps {
    struct Channel: Codable {
        let name: String
        let presence: [Presence]
    }
}

/**
 Presence (Channel)
 */
extension TestAppSetup.PostApps.Channel {
    struct Presence: Codable {
        let clientId: String
        let data: String
        let encoding: String?
    }
}

/**
 Presence (Limits)
 */
extension TestAppSetup.PostApps.Limits {
    struct Presence: Codable {
        let maxMembers: Int
    }
}

/**
 Cipher
 */
extension TestAppSetup {
    struct Cipher: Codable {
        let algorithm: String
        let mode: String
        let keylength: Int
        let key: String
        let iv: String
    }
}
