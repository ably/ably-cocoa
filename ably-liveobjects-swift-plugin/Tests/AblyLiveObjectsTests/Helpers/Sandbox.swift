import Foundation

/// Provides the ``createAPIKey()`` function to create an API key for the Ably sandbox environment.
enum Sandbox {
    private struct TestApp: Codable {
        var keys: [Key]

        struct Key: Codable {
            var keyStr: String
        }
    }

    enum Error: Swift.Error {
        case badResponseStatus(Int)
    }

    private static func loadAppCreationRequestBody() async throws -> Data {
        let testAppSetupFileURL = Bundle.module.url(
            forResource: "test-app-setup",
            withExtension: "json",
            subdirectory: "ably-common/test-resources",
        )!

        let (data, _) = try await URLSession.shared.data(for: .init(url: testAppSetupFileURL))
        // swiftlint:disable:next force_cast
        let dictionary = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return try JSONSerialization.data(withJSONObject: dictionary["post_apps"]!)
    }

    static func createAPIKey() async throws -> String {
        var request = URLRequest(url: .init(string: "https://sandbox-rest.ably.io/apps")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try await loadAppCreationRequestBody()

        let (data, response) = try await URLSession.shared.data(for: request)

        // swiftlint:disable:next force_cast
        let statusCode = (response as! HTTPURLResponse).statusCode

        guard (200 ..< 300).contains(statusCode) else {
            throw Error.badResponseStatus(statusCode)
        }

        let testApp = try JSONDecoder().decode(TestApp.self, from: data)

        // From JS chat repo at 7985ab7 — "The key we need to use is the one at index 5, which gives enough permissions to interact with Chat and Channels"
        return testApp.keys[5].keyStr
    }

    /// An actor that manages a cached API key for the Ably sandbox environment.
    private actor APIKeyManager {
        /// The cached API key, if one has been successfully generated
        private var cachedKey: String?

        /// The current key generation task, if one is in progress
        private var keyGenerationTask: Task<String, Swift.Error>?

        /// Retrieves an API key, either from cache or by generating a new one.
        ///
        /// - Returns: An API key for the Ably sandbox environment
        /// - Throws: Any error that occurred during key generation
        func getKey() async throws -> String {
            if let cachedKey {
                return cachedKey
            }

            if let existingTask = keyGenerationTask {
                return try await existingTask.value
            }

            let task = Task {
                defer { keyGenerationTask = nil }
                let key = try await createAPIKey()
                cachedKey = key
                return key
            }
            keyGenerationTask = task
            return try await task.value
        }
    }

    private static let keyManager = APIKeyManager()

    /// Fetches an API key for the Ably sandbox environment. If a key has already been generated, returns the cached key.
    ///
    /// - Returns: A valid API key for the Ably sandbox environment
    /// - Throws: Any error that occurred during key generation
    static func fetchSharedAPIKey() async throws -> String {
        try await keyManager.getKey()
    }
}
