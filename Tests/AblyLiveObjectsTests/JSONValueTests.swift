@testable import AblyLiveObjects
import Foundation
import Testing

struct JSONValueTests {
    // MARK: Conversion from AblyPlugin data

    @Test(arguments: [
        // object
        (ablyPluginData: ["someKey": "someValue"], expectedResult: ["someKey": "someValue"]),
        // array
        (ablyPluginData: ["someElement"], expectedResult: ["someElement"]),
        // string
        (ablyPluginData: "someString", expectedResult: "someString"),
        // number
        (ablyPluginData: NSNumber(value: 0), expectedResult: 0),
        (ablyPluginData: NSNumber(value: 1), expectedResult: 1),
        (ablyPluginData: NSNumber(value: 123), expectedResult: 123),
        (ablyPluginData: NSNumber(value: 123.456), expectedResult: 123.456),
        // bool
        (ablyPluginData: NSNumber(value: true), expectedResult: true),
        (ablyPluginData: NSNumber(value: false), expectedResult: false),
        // null
        (ablyPluginData: NSNull(), expectedResult: .null),
    ] as[(ablyPluginData: Sendable, expectedResult: JSONValue?)])
    func initWithAblyPluginData(ablyPluginData: Sendable, expectedResult: JSONValue?) {
        #expect(JSONValue(ablyPluginData: ablyPluginData) == expectedResult)
    }

    // Tests that it correctly handles an object deserialized by `JSONSerialization` (which is what ably-cocoa uses for deserialization).
    @Test
    func initWithAblyPluginData_endToEnd() throws {
        let jsonString = """
        {
          "someArray": [
            {
              "someStringKey": "someString",
              "zero": 0,
              "one": 1,
              "someIntegerKey": 123,
              "someFloatKey": 123.456,
              "someTrueKey": true,
              "someFalseKey": false,
              "someNullKey": null
            },
            "someOtherArrayElement"
          ],
          "someNestedObject": {
            "someOtherKey": "someOtherValue"
          }
        }
        """

        let ablyPluginData = try JSONSerialization.jsonObject(with: #require(jsonString.data(using: .utf8)))

        let expected: JSONValue = [
            "someArray": [
                [
                    "someStringKey": "someString",
                    "zero": 0,
                    "one": 1,
                    "someIntegerKey": 123,
                    "someFloatKey": 123.456,
                    "someTrueKey": true,
                    "someFalseKey": false,
                    "someNullKey": .null,
                ],
                "someOtherArrayElement",
            ],
            "someNestedObject": [
                "someOtherKey": "someOtherValue",
            ],
        ]

        #expect(JSONValue(ablyPluginData: ablyPluginData) == expected)
    }

    // MARK: Conversion to AblyPlugin data

    @Test(arguments: [
        // object
        (value: ["someKey": "someValue"], expectedResult: ["someKey": "someValue"]),
        // array
        (value: ["someElement"], expectedResult: ["someElement"]),
        // string
        (value: "someString", expectedResult: "someString"),
        // number
        (value: 0, expectedResult: NSNumber(value: 0)),
        (value: 1, expectedResult: NSNumber(value: 1)),
        (value: 123, expectedResult: NSNumber(value: 123)),
        (value: 123.456, expectedResult: NSNumber(value: 123.456)),
        // bool
        (value: true, expectedResult: NSNumber(value: true)),
        (value: false, expectedResult: NSNumber(value: false)),
        // null
        (value: .null, expectedResult: NSNull()),
    ] as[(value: JSONValue, expectedResult: Sendable)])
    func toAblyPluginData(value: JSONValue, expectedResult: Sendable) throws {
        let resultAsNSObject = try #require(value.toAblyPluginData as? NSObject)
        let expectedResultAsNSObject = try #require(expectedResult as? NSObject)
        #expect(resultAsNSObject == expectedResultAsNSObject)
    }

    // Tests that it creates an object that can be serialized by `JSONSerialization` (which is what ably-cocoa uses for serialization), and that the result of this serialization is what we’d expect.
    @Test
    func toAblyPluginData_endToEnd() throws {
        let value: JSONValue = [
            "someArray": [
                [
                    "someStringKey": "someString",
                    "zero": 0,
                    "one": 1,
                    "someIntegerKey": 123,
                    "someFloatKey": 123.456,
                    "someTrueKey": true,
                    "someFalseKey": false,
                    "someNullKey": .null,
                ],
                "someOtherArrayElement",
            ],
            "someNestedObject": [
                "someOtherKey": "someOtherValue",
            ],
        ]

        let expectedJSONString = """
        {
          "someArray": [
            {
              "someStringKey": "someString",
              "someIntegerKey": 123,
              "someFloatKey": 123.456,
              "zero": 0,
              "one": 1,
              "someTrueKey": true,
              "someFalseKey": false,
              "someNullKey": null
            },
            "someOtherArrayElement"
          ],
          "someNestedObject": {
            "someOtherKey": "someOtherValue"
          }
        }
        """

        let jsonSerializationOptions: JSONSerialization.WritingOptions = [.sortedKeys]

        let valueData = try JSONSerialization.data(withJSONObject: value.toAblyPluginData, options: jsonSerializationOptions)
        let expectedData = try {
            let serialized = try JSONSerialization.jsonObject(with: #require(expectedJSONString.data(using: .utf8)))
            return try JSONSerialization.data(withJSONObject: serialized, options: jsonSerializationOptions)
        }()

        #expect(valueData == expectedData)
    }
}
