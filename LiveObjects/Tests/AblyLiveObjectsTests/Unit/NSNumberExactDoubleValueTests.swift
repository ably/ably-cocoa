@testable import AblyLiveObjects
import Foundation
import Testing

/// Tests for `NSNumber.art_doubleValue`, which the SDK uses in place of `doubleValue`
/// when reading numbers that came out of `JSONSerialization`. See the doc comment on that property for
/// why it exists.
struct NSNumberExactDoubleValueTests {
    private static func parse(_ text: String) throws -> NSNumber {
        let object = try JSONSerialization.jsonObject(with: Data(text.utf8), options: [.fragmentsAllowed])
        return try #require(object as? NSNumber)
    }

    // Values whose shortest textual form `JSONSerialization` hands back as an `NSDecimalNumber`, where
    // `doubleValue` lands one or two ULP away from the original. Found by fuzzing in the 0.001...1000
    // range, so these are the sort of amount a `LiveCounter` might plausibly hold.
    @Test(arguments: [
        0.015034388851090229,
        0.023942638935083197,
        0.033958698936617585,
        0.025558854016674924,
        0.012719384279025869,
        0.013029106591963293,
        0.034000795543243395,
        0.050053335337711245,
        0.010050170732297348,
    ] as [Double])
    func recoversValuesThatDoubleValueRounds(value: Double) throws {
        let parsed = try Self.parse(String(value))

        #expect(parsed.art_doubleValue == value)
    }

    // Ordinary numbers, which arrive as a plain `NSNumber` already holding the closest `Double`. These
    // guard the `NSDecimalNumber` test in the implementation: reading them back from `stringValue`
    // instead would round to 16 significant digits, turning `greatestFiniteMagnitude` into infinity.
    @Test(arguments: [
        0,
        1,
        -42,
        0.1,
        0.5,
        123.456,
        1e21,
        0x1p53,
        1e-7,
        .leastNonzeroMagnitude,
        .greatestFiniteMagnitude,
        -.greatestFiniteMagnitude,
        .pi,
    ] as [Double])
    func agreesWithDoubleValueForOrdinaryNumbers(value: Double) throws {
        let parsed = try Self.parse(String(value))

        #expect(parsed.art_doubleValue == value)
    }

    // The reason the property exists is the bridge that reads decoded JSON into a `JSONValue`, so check
    // it end to end rather than only through the property.
    @Test(arguments: [
        0.015034388851090229,
        0.023942638935083197,
        123.456,
        .greatestFiniteMagnitude,
    ] as [Double])
    func jsonValueBridgePreservesTheValue(value: Double) throws {
        let text = #"{"amount":\#(String(value))}"#
        let deserialized = try JSONSerialization.jsonObject(with: Data(text.utf8))

        let jsonValue = JSONValue(jsonSerializationOutput: deserialized)

        #expect(jsonValue == ["amount": .number(value)])
    }
}
