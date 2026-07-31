import Ably
@testable import AblyLiveObjects
import Testing

/// Tests for `SyncCursor`'s parsing of an `OBJECT_SYNC` `channelSerial` (RTO5a1, RTO5a4).
///
/// A non-conforming `channelSerial` parses to `nil`; the resulting behaviour (treated as an absent
/// `channelSerial` per RTO5a5) is exercised end-to-end in
/// `InternalDefaultRealtimeObjectsTests.HandleObjectSyncProtocolMessageTests`.
struct SyncCursorTests {
    // The parsing described in RTO5a1: `<sequence id>:<cursor value>`.
    @Test
    func validChannelSerialWithCursorValue() throws {
        // Given
        let channelSerial = "sequence123:cursor456"

        // When
        let cursor = try #require(SyncCursor(channelSerial: channelSerial))

        // Then
        #expect(cursor.sequenceID == "sequence123")
        #expect(cursor.cursorValue == "cursor456")
        #expect(!cursor.isEndOfSequence)
    }

    // RTO5a4: the sequence is complete once the cursor is empty, i.e. `<sequence id>:`.
    @Test
    func validChannelSerialAtEndOfSequence() throws {
        // Given
        let channelSerial = "sequence123:"

        // When
        let cursor = try #require(SyncCursor(channelSerial: channelSerial))

        // Then
        #expect(cursor.sequenceID == "sequence123")
        #expect(cursor.cursorValue == nil)
        #expect(cursor.isEndOfSequence)
    }

    // We deliberately do not restrict the sequence-id character set (unlike ably-java's `[\w-]+`
    // regex). The specification places no such restriction, so any characters up to the first colon
    // form the sequence id. This includes hyphens and underscores...
    @Test
    func validChannelSerialWithHyphenAndUnderscoreSequenceID() throws {
        // Given
        let channelSerial = "seq-1_2:cursor456"

        // When
        let cursor = try #require(SyncCursor(channelSerial: channelSerial))

        // Then
        #expect(cursor.sequenceID == "seq-1_2")
        #expect(cursor.cursorValue == "cursor456")
    }

    // ...and also characters that ably-java's `[\w-]+` regex would reject (here, a dot). We accept
    // them because rejecting an otherwise-valid serial would risk silently dropping a real sync. The
    // colon is the first one, so the dot forms part of the sequence id, not the cursor value.
    @Test
    func validChannelSerialWithNonWordCharactersInSequenceID() throws {
        // Given
        let channelSerial = "seq.a:cursor456"

        // When
        let cursor = try #require(SyncCursor(channelSerial: channelSerial))

        // Then
        #expect(cursor.sequenceID == "seq.a")
        #expect(cursor.cursorValue == "cursor456")
    }

    // A channelSerial with no colon separator does not conform to RTO5a1, so it parses to `nil`. The
    // caller then treats the OBJECT_SYNC as self-contained (RTO5a5); see
    // `HandleObjectSyncProtocolMessageTests.treatsChannelSerialWithoutColonAsSelfContainedSync`.
    @Test
    func channelSerialWithoutColonReturnsNil() {
        #expect(SyncCursor(channelSerial: "sequence123") == nil)
    }

    // An empty channelSerial does not conform to RTO5a1, so it parses to `nil`.
    @Test
    func emptyChannelSerialReturnsNil() {
        #expect(SyncCursor(channelSerial: "") == nil)
    }

    // The specification is not explicit about an empty sequence id, but a sync sequence cannot be
    // meaningfully identified (RTO5a2/RTO5a3 compare sequence ids) without one. For cross-SDK
    // consistency with ably-java (whose `[\w-]+` regex requires a non-empty sequence id) we reject
    // it; it parses to `nil` and is treated as a self-contained OBJECT_SYNC (RTO5a5).
    //
    // This reverses the previous cocoa behaviour, which accepted an empty sequence id.
    @Test
    func channelSerialWithEmptySequenceIDReturnsNil() {
        #expect(SyncCursor(channelSerial: ":cursor456") == nil)
    }

    // As above, an empty sequence id is rejected even when the cursor is also empty.
    @Test
    func channelSerialWithEmptySequenceIDAtEndOfSequenceReturnsNil() {
        #expect(SyncCursor(channelSerial: ":") == nil)
    }
}
