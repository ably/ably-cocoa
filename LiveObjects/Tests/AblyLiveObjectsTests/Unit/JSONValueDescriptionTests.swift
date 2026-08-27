@testable import AblyLiveObjects
import Foundation
import Testing

/// Tests for `JSONValue`'s `CustomStringConvertible` and `CustomDebugStringConvertible` conformances
///
/// The conformances render compact JSON text directly rather than going through
/// `JSONSerialization`, which writes numbers to 17 significant digits rather than the shortest form
/// that round-trips. Numbers come from `Double`'s own description, so where that chooses exponent
/// notation differently from JS `JSON.stringify` the output differs too; the tests below record
/// those cases.
struct JSONValueDescriptionTests {
    // MARK: - Scalars

    @Test(arguments: [
        (value: JSONValue.null, expected: "null"),
        (value: true, expected: "true"),
        (value: false, expected: "false"),
        (value: "someString", expected: #""someString""#),
        (value: "", expected: #""""#),
    ] as [(value: JSONValue, expected: String)])
    func scalars(value: JSONValue, expected: String) {
        #expect(value.description == expected)
    }

    // MARK: - Numbers

    @Test(arguments: [
        // The point of the issue: an integral value is written without the fractional part that
        // `Double`'s own description would give it.
        (value: 0.0, expected: "0"),
        (value: 1, expected: "1"),
        (value: 10, expected: "10"),
        (value: -42, expected: "-42"),
        (value: 123.456, expected: "123.456"),
        (value: -0.5, expected: "-0.5"),
        (value: 1e15, expected: "1000000000000000"),
    ] as [(value: Double, expected: String)])
    func numbers(value: Double, expected: String) {
        #expect(JSONValue.number(value).description == expected)
    }

    // A value that is not exactly representable in binary floating point is written with the fewest
    // digits that identify it uniquely, rather than its full 17-significant-digit expansion. This is
    // the case a LiveObjects user is most likely to hit — a counter holding a fractional amount.
    @Test(arguments: [
        (value: 0.1, expected: "0.1"),
        (value: 0.3, expected: "0.3"),
        (value: 1.1, expected: "1.1"),
        (value: 0.1 + 0.2, expected: "0.30000000000000004"), // genuinely a different Double from 0.3
    ] as [(value: Double, expected: String)])
    func fractionalNumbersUseShortestRoundTrip(value: Double, expected: String) {
        #expect(JSONValue.number(value).description == expected)
    }

    // Where `Double`'s description switches to exponent notation is inherited rather than chosen, so it
    // does not always agree with the other SDKs: the trailing comments give `JSON.stringify`'s output
    // where it differs.
    @Test(arguments: [
        (value: -0.0, expected: "-0"), // JSON.stringify: 0
        (value: 1e18, expected: "1e+18"), // JSON.stringify: 1000000000000000000
        (value: 1e19, expected: "1e+19"), // JSON.stringify: 10000000000000000000
        (value: 1e21, expected: "1e+21"),
        // 2^53, the last integer whose neighbours are all exactly representable.
        (value: 0x1p53, expected: "9007199254740992"),
        // Above 2^53 the digits are still the shortest that round-trip, so no exact expansion appears.
        (value: 1_000_000_000_000_000_128, expected: "1.0000000000000001e+18"), // JSON.stringify: 1000000000000000100
        (value: 1.2345678901234567e19, expected: "1.2345678901234567e+19"), // JSON.stringify: 12345678901234567000
        (value: 1e-6, expected: "1e-6"), // JSON.stringify: 0.000001
        (value: 1e-7, expected: "1e-7"),
        (value: 1e-21, expected: "1e-21"),
        (value: .greatestFiniteMagnitude, expected: "1.7976931348623157e+308"),
        (value: .leastNonzeroMagnitude, expected: "5e-324"),
    ] as [(value: Double, expected: String)])
    func numberEdgeCases(value: Double, expected: String) {
        #expect(JSONValue.number(value).description == expected)
    }

    // The two pieces of punctuation that are stripped from `Double`'s description.
    @Test(arguments: [
        (value: 10.0, expected: "10"), // not 10.0
        (value: 0.0, expected: "0"), // not 0.0
        (value: 1e15, expected: "1000000000000000"), // not 1000000000000000.0
        (value: 1e-7, expected: "1e-7"), // not 1e-07
        (value: 8.706394e-7, expected: "8.706394e-7"), // not 8.706394e-07
        // Padding is only ever stripped from the exponent, never from the digits themselves.
        (value: 100.0, expected: "100"),
        (value: 1e-21, expected: "1e-21"),
        (value: .greatestFiniteMagnitude, expected: "1.7976931348623157e+308"),
    ] as [(value: Double, expected: String)])
    func punctuationStrippedFromDoubleDescription(value: Double, expected: String) {
        #expect(JSONValue.number(value).description == expected)
    }

    // Whatever layout is chosen, the digits have to identify the original value exactly.
    @Test(arguments: [
        0.1,
        0.1 + 0.2,
        123.456,
        1e-7,
        1e-21,
        1_000_000_000_000_000_128,
        1.2345678901234567e19,
        1e21,
        .greatestFiniteMagnitude,
        .leastNonzeroMagnitude,
        .pi,
    ] as [Double])
    func numbersRoundTrip(value: Double) throws {
        let text = JSONValue.number(value).description

        #expect(try #require(Double(text)) == value)
    }

    // `JSONValue.number` wraps a `Double`, so the non-finite values are constructible from public API
    // and have to render as something. JSON cannot represent them; they are written as null, which is
    // what `JSON.stringify` does.
    //
    // `signalingNaN` is not in the arguments: it takes the same branch as `nan` and describes
    // identically, which gives the two cases the same identity and makes xcodebuild's reporter
    // reject the second as already started.
    @Test(arguments: [Double.nan, .infinity, -.infinity])
    func nonFiniteNumbersAreNull(value: Double) {
        #expect(JSONValue.number(value).description == "null")
    }

    // MARK: - String escaping

    @Test(arguments: [
        (value: #"say "hi""#, expected: #""say \"hi\"""#),
        (value: #"back\slash"#, expected: #""back\\slash""#),
        (value: "line\nbreak", expected: #""line\nbreak""#),
        (value: "carriage\rreturn", expected: #""carriage\rreturn""#),
        (value: "tab\tseparated", expected: #""tab\tseparated""#),
        (value: "back\u{08}space", expected: #""back\bspace""#),
        (value: "form\u{0C}feed", expected: #""form\ffeed""#),
        // Other control characters take the \u form, with lowercase hex.
        (value: "nul\u{00}byte", expected: #""nul\u0000byte""#),
        (value: "bell\u{07}", expected: #""bell\u0007""#),
        (value: "escape\u{1B}", expected: #""escape\u001b""#),
    ] as [(value: String, expected: String)])
    func stringEscaping(value: String, expected: String) {
        #expect(JSONValue.string(value).description == expected)
    }

    // JSON permits escaping the forward slash but does not require it, so it is left alone and URLs
    // stay readable.
    @Test
    func forwardSlashesAreNotEscaped() {
        let value = JSONValue.string("https://example.com/a/b")

        #expect(value.description == #""https://example.com/a/b""#)
    }

    @Test(arguments: ["héllo", "日本語", "👍🏽", "a\u{0301}"])
    func nonASCIICharactersArePreserved(value: String) {
        #expect(JSONValue.string(value).description == "\"\(value)\"")
    }

    // MARK: - Objects and arrays

    @Test
    func emptyContainers() {
        #expect(JSONValue.object([:]).description == "{}")
        #expect(JSONValue.array([]).description == "[]")
    }

    @Test
    func objectKeysAreSorted() {
        let value: JSONValue = [
            "likes": 10,
            "hearts": 0,
            "claps": 3,
            "wows": 7,
            "laughs": 1,
        ]

        #expect(value.description == #"{"claps":3,"hearts":0,"laughs":1,"likes":10,"wows":7}"#)
    }

    // Keys sort lexicographically by Unicode scalar, so digits sort as text ("10" before "2") and
    // uppercase before lowercase. Pinned because "sorted" admits several readings, and because the
    // ordering has to be stable for the output to be comparable between runs.
    @Test
    func keySortIsLexicographic() {
        let value = JSONValue.object([
            "b": 1,
            "A": 2,
            "a": 3,
            "10": 4,
            "2": 5,
            "_": 6,
            "é": 7,
            "e": 8,
        ])

        #expect(value.description == #"{"10":4,"2":5,"A":2,"_":6,"a":3,"b":1,"e":8,"é":7}"#)
    }

    // The point of sorting: the same content renders identically however the dictionary was built,
    // and whatever order it happens to have internally on this run.
    @Test
    func objectRenderingIsDeterministic() {
        let insertionOrders: [[(String, JSONValue)]] = [
            [("likes", 10), ("hearts", 0), ("claps", 3)],
            [("claps", 3), ("likes", 10), ("hearts", 0)],
            [("hearts", 0), ("claps", 3), ("likes", 10)],
        ]

        let renderings = insertionOrders.map { pairs in
            JSONValue.object(.init(uniqueKeysWithValues: pairs)).description
        }

        #expect(Set(renderings).count == 1)
        #expect(renderings[0] == #"{"claps":3,"hearts":0,"likes":10}"#)
    }

    @Test
    func objectKeysAreEscaped() {
        let value = JSONValue.object([#"a"b"#: 1])

        #expect(value.description == #"{"a\"b":1}"#)
    }

    @Test
    func emptyKeyIsValid() {
        let value = JSONValue.object(["": 1])

        #expect(value.description == #"{"":1}"#)
    }

    // Unlike objects, arrays keep their order.
    @Test
    func arrayOrderIsPreserved() {
        let value: JSONValue = ["c", "a", "b"]

        #expect(value.description == #"["c","a","b"]"#)
    }

    @Test
    func nestedContainers() {
        let value: JSONValue = [
            "counter": 10,
            "meta": [
                "tags": ["x", "y"],
                "enabled": false,
                "missing": .null,
            ],
            "list": [1, [2, [3]]],
        ]

        #expect(
            value.description == #"{"counter":10,"list":[1,[2,[3]]],"meta":{"enabled":false,"missing":null,"tags":["x","y"]}}"#,
        )
    }

    // MARK: - Debug description

    @Test(arguments: [
        JSONValue.null,
        true,
        123.456,
        "someString",
        ["someKey": "someValue"],
        ["someElement", 1],
    ] as [JSONValue])
    func debugDescriptionMatchesDescription(value: JSONValue) {
        #expect(value.debugDescription == value.description)
    }

    // The conformances are what `print`, string interpolation and LLDB's `po` go through, so check the
    // value reaches them rather than only reading the properties directly.
    @Test
    func standardRenderingEntryPoints() {
        let value: JSONValue = ["likes": 10, "hearts": 0]
        let expected = #"{"hearts":0,"likes":10}"#
        let interpolated = "\(value)"

        #expect(interpolated == expected)
        #expect(String(describing: value) == expected)
        #expect(String(reflecting: value) == expected)
    }

    // MARK: - Output is valid JSON

    // Whatever is printed has to parse back to the value it came from.
    @Test(arguments: [
        JSONValue.null,
        true,
        false,
        0,
        10,
        -42,
        123.456,
        0.1,
        1e21,
        "someString",
        "",
        .string(#"quotes " backslash \ newline"# + "\n\u{07}"),
        "https://example.com/a/b",
        "日本語 👍🏽",
        [:],
        [],
        ["someKey": "someValue", "nested": ["a": [1, 2, .null]], "n": 10],
        ["someElement", 1, true, .null, ["k": "v"]],
    ] as [JSONValue])
    func descriptionRoundTrips(value: JSONValue) throws {
        let data = try #require(value.description.data(using: .utf8))
        let deserialized = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])

        #expect(JSONValue(jsonSerializationOutput: deserialized) == value)
    }

    // The rendering has to agree with the `JSONSerialization` bridge that is used to put a `JSONValue`
    // on the wire, otherwise what a user is shown is not what gets published.
    @Test(arguments: [
        JSONValue.null,
        true,
        0,
        10,
        -42,
        123.456,
        0.1,
        // `JSONSerialization` hands these back as `NSDecimalNumber` rather than as a `Double`. Both
        // sides of the comparison go through the same bridge, so what is checked is that the printer
        // and the bridge agree, whatever that conversion does to the value.
        0.015034388851090229,
        0.023942638935083197,
        "someString",
        "https://example.com/a/b",
        "日本語 👍🏽",
        [:],
        [],
        ["someKey": "someValue", "nested": ["a": [1, 2, .null]], "n": 10],
        ["someElement", 1, true, .null, ["k": "v"]],
    ] as [JSONValue])
    func descriptionAgreesWithJSONSerializationBridge(value: JSONValue) throws {
        let data = try #require(value.description.data(using: .utf8))
        let reparsed = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])

        let bridged = try JSONSerialization.data(
            withJSONObject: value.toJSONSerializationInputElement,
            options: [.fragmentsAllowed],
        )
        let bridgeParsed = try JSONSerialization.jsonObject(with: bridged, options: [.fragmentsAllowed])

        #expect(JSONValue(jsonSerializationOutput: reparsed) == JSONValue(jsonSerializationOutput: bridgeParsed))
    }
}
