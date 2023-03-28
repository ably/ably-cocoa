import XCTest
import Ably.Private

class ResumeRequestResponseTests: XCTestCase {
    func test_valid() {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .connected
        protocolMessage.connectionId = "123" // same as currentConnectionID below

        let errorChecker = MockErrorChecker()

        let response = ResumeRequestResponse(
            currentConnectionID: "123", // arbitrarily chosen
            protocolMessage: protocolMessage,
            errorChecker: errorChecker
        )

        XCTAssertEqual(response.type, .valid)
        XCTAssertNil(response.error)
    }

    func test_invalid() {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .connected
        protocolMessage.connectionId = "456" // arbitrarily chosen, different to currentConnectionID below
        protocolMessage.error = .init() // arbitrarily chosen

        let errorChecker = MockErrorChecker()

        let response = ResumeRequestResponse(
            currentConnectionID: "123", // arbitrarily chosen
            protocolMessage: protocolMessage,
            errorChecker: errorChecker
        )

        XCTAssertEqual(response.type, .invalid)
        XCTAssertEqual(response.error, protocolMessage.error)
    }

    func test_tokenError() {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .error
        protocolMessage.error = .init() // arbitrarily chosen

        let errorChecker = MockErrorChecker()
        errorChecker.isTokenError = true

        let response = ResumeRequestResponse(
            currentConnectionID: "123", // arbitrarily chosen
            protocolMessage: protocolMessage,
            errorChecker: errorChecker
        )

        XCTAssertEqual(response.type, .tokenError)
        XCTAssertEqual(response.error, protocolMessage.error)
    }

    func test_fatalError() {
        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .error
        protocolMessage.error = .init() // arbitrarily chosen

        let errorChecker = MockErrorChecker()
        errorChecker.isTokenError = false

        let response = ResumeRequestResponse(
            currentConnectionID: "123",
            protocolMessage: protocolMessage,
            errorChecker: errorChecker
        )

        XCTAssertEqual(response.type, .fatalError)
        XCTAssertEqual(response.error, protocolMessage.error)
    }

    func test_unknown() {
        // For example, a CONNECTED ProtocolMessage with the same connection ID but with an error

        let protocolMessage = ARTProtocolMessage()
        protocolMessage.action = .connected
        protocolMessage.connectionId = "123" // same as currentConnectionID below
        protocolMessage.error = .init() // arbitrarily chosen

        let errorChecker = MockErrorChecker()

        let response = ResumeRequestResponse(
            currentConnectionID: "123", // arbitrarily chosen
            protocolMessage: protocolMessage,
            errorChecker: errorChecker
        )

        XCTAssertEqual(response.type, .unknown)
        XCTAssertNil(response.error)
    }
}
