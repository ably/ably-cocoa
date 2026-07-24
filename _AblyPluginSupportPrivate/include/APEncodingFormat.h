/// The wire format to which a plugin object should encode an object or from which a plugin should be decode an object.
///
/// The requirements for encoding to and decoding from each format are as follows:
///
/// - `APEncodingFormatJSON`:
///   - Encoding: Plugins should generate an object that ably-cocoa can pass to Foundation's `JSONSerialization.data(withJSONObject:,…)`.
///   - Decoding: Plugins should expect to find the same types of values as you would in the output of Foundation's `JSONSerialization`.
/// - `APEncodingFormatMessagePack`:
///   - Encoding: As for `APEncodingFormatJSON`, but arrays and dictionaries are allowed to additionally contain `NSData` values.
///   - Decoding: As for `APEncodingFormatJSON`, but arrays and dictionaries may also additionally contain `NSData` values.
///
/// We intentionally use a closed enum so that plugins do not have to include an `@unknown default` (since there is no sensible default for them to use; if we introduce a new encoding format in the future then we will have to define new logic — and since it's a closed enum, a new enum).
typedef NS_CLOSED_ENUM(NSInteger, APEncodingFormat) {
    APEncodingFormatJSON NS_SWIFT_NAME(json),
    APEncodingFormatMessagePack
} NS_SWIFT_NAME(EncodingFormat);
