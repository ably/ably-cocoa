@testable import AblyLiveObjects
import Foundation
import Testing

struct JSONValueTests {
    // MARK: Conversion from JSONSerialization output

    @Test(arguments: [
        // object
        (jsonSerializationOutput: ["someKey": "someValue"], expectedResult: ["someKey": "someValue"]),
        // array
        (jsonSerializationOutput: ["someElement"], expectedResult: ["someElement"]),
        // string
        (jsonSerializationOutput: "someString", expectedResult: "someString"),
        // number
        (jsonSerializationOutput: NSNumber(value: 0), expectedResult: 0),
        (jsonSerializationOutput: NSNumber(value: 1), expectedResult: 1),
        (jsonSerializationOutput: NSNumber(value: 123), expectedResult: 123),
        (jsonSerializationOutput: NSNumber(value: 123.456), expectedResult: 123.456),
        // bool
        (jsonSerializationOutput: NSNumber(value: true), expectedResult: true),
        (jsonSerializationOutput: NSNumber(value: false), expectedResult: false),
        // null
        (jsonSerializationOutput: NSNull(), expectedResult: .null),
    ] as[(jsonSerializationOutput: Sendable, expectedResult: JSONValue?)])
    func initWithJSONSerializationOutput(jsonSerializationOutput: Sendable, expectedResult: JSONValue?) {
        #expect(JSONValue(jsonSerializationOutput: jsonSerializationOutput) == expectedResult)
    }

    // Tests that it correctly handles an object deserialized by `JSONSerialization`.
    @Test
    func initWithJSONSerializationOutput_endToEnd() throws {
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

        let jsonSerializationOutput = try JSONSerialization.jsonObject(with: #require(jsonString.data(using: .utf8)))

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

        #expect(JSONValue(jsonSerializationOutput: jsonSerializationOutput) == expected)
    }

    // MARK: Conversion to JSONSerialization input

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
    func toJSONSerializationInput(value: JSONValue, expectedResult: Sendable) throws {
        let resultAsNSObject = try #require(value.toJSONSerializationInputElement as? NSObject)
        let expectedResultAsNSObject = try #require(expectedResult as? NSObject)
        #expect(resultAsNSObject == expectedResultAsNSObject)
    }

    // Tests that it creates an object that can be serialized by `JSONSerialization`, and that the result of this serialization is what we’d expect.
    @Test
    func toJSONSerializationInput_endToEnd() throws {
        let value: [String: JSONValue] = [
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

        let valueData = try JSONSerialization.data(withJSONObject: value.toJSONSerializationInput, options: jsonSerializationOptions)
        let expectedData = try {
            let serialized = try JSONSerialization.jsonObject(with: #require(expectedJSONString.data(using: .utf8)))
            return try JSONSerialization.data(withJSONObject: serialized, options: jsonSerializationOptions)
        }()

        #expect(valueData == expectedData)
    }
}
