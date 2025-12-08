import Foundation

extension String {
    enum DecodingError: Swift.Error {
        case decodingFailed
    }

    /// Like `init(data:encoding:)`, but indicates decoding failure by throwing an error instead of returning an optional.
    init(data: Data, encoding: String.Encoding) throws {
        guard let decoded = String(data: data, encoding: encoding) else {
            throw DecodingError.decodingFailed
        }

        self = decoded
    }
}
