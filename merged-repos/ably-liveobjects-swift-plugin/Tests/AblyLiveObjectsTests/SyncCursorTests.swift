import Ably
@testable import AblyLiveObjects
import Testing

struct SyncCursorTests {
    // The parsing described in RTO5a1
    @Test
    func validChannelSerialWithCursorValue() throws {
        // Given
        let channelSerial = "sequence123:cursor456"

        // When
        let cursor = try SyncCursor(channelSerial: channelSerial)

        // Then
        #expect(cursor.sequenceID == "sequence123")
        #expect(cursor.cursorValue == "cursor456")
        #expect(!cursor.isEndOfSequence)
    }

    // The scenario described in RTO5a2
    @Test
    func validChannelSerialAtEndOfSequence() throws {
        // Given
        let channelSerial = "sequence123:"

        // When
        let cursor = try SyncCursor(channelSerial: channelSerial)

        // Then
        #expect(cursor.sequenceID == "sequence123")
        #expect(cursor.cursorValue == nil)
        #expect(cursor.isEndOfSequence)
    }

    @Test
    func invalidChannelSerialWithoutColon() {
        // Given
        let channelSerial = "sequence123"

        // When/Then
        do {
            _ = try SyncCursor(channelSerial: channelSerial)
            Issue.record("Expected error was not thrown")
        } catch {
            guard let liveObjectsError = error.testsOnly_underlyingLiveObjectsError,
                  case .other(SyncCursor.Error.channelSerialDoesNotMatchExpectedFormat) = liveObjectsError
            else {
                Issue.record("Expected channelSerialDoesNotMatchExpectedFormat error")
                return
            }
        }
    }

    @Test
    func invalidEmptyChannelSerial() {
        // Given
        let channelSerial = ""

        // When/Then
        do {
            _ = try SyncCursor(channelSerial: channelSerial)
            Issue.record("Expected error was not thrown")
        } catch {
            guard let liveObjectsError = error.testsOnly_underlyingLiveObjectsError,
                  case .other(SyncCursor.Error.channelSerialDoesNotMatchExpectedFormat) = liveObjectsError
            else {
                Issue.record("Expected channelSerialDoesNotMatchExpectedFormat error")
                return
            }
        }
    }

    // The spec isn't explicit here but doesn't rule this out
    @Test
    func validChannelSerialWithEmptySequenceID() throws {
        // Given
        let channelSerial = ":cursor456"

        // When
        let cursor = try SyncCursor(channelSerial: channelSerial)

        // Then
        // swiftlint:disable:next empty_string
        #expect(cursor.sequenceID == "")
        #expect(cursor.cursorValue == "cursor456")
        #expect(!cursor.isEndOfSequence)
    }

    // The spec isn't explicit here but doesn't rule this out
    @Test
    func validChannelSerialWithEmptySequenceIDAtEndOfSequence() throws {
        // Given
        let channelSerial = ":"

        // When
        let cursor = try SyncCursor(channelSerial: channelSerial)

        // Then
        // swiftlint:disable:next empty_string
        #expect(cursor.sequenceID == "")
        #expect(cursor.cursorValue == nil)
        #expect(cursor.isEndOfSequence)
    }
}
