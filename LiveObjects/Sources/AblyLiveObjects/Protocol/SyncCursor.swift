import Foundation

/// The `OBJECT_SYNC` sync cursor, as extracted from a `channelSerial` per RTO5a1 and RTO5a4.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal struct SyncCursor {
    internal var sequenceID: String
    /// `nil` in the case where the objects sync sequence is complete (RTO5a4).
    internal var cursorValue: String?

    /// Creates a `SyncCursor` from the `channelSerial` of an `OBJECT_SYNC` `ProtocolMessage`.
    ///
    /// Per RTO5a1 the `channelSerial` is a two-part identifier `<sequence id>:<cursor value>`.
    ///
    /// Returns `nil` if `channelSerial` does not conform to that shape — that is, if it has no
    /// colon separator or an empty sequence id. The specification does not define behaviour for a
    /// non-conforming (but present) `channelSerial`; for cross-SDK consistency with ably-java the
    /// caller treats a `nil` result the same as an absent `channelSerial` (RTO5a5), i.e. the sync
    /// data is taken to be entirely contained within the single `OBJECT_SYNC`.
    ///
    /// Note that, unlike ably-java's `^([\w-]+):(.*)$` regex, we do not restrict the sequence-id
    /// character set: any characters up to the first colon are accepted. The specification places
    /// no such restriction, and rejecting an otherwise-valid serial merely because of an unusual
    /// character would risk silently dropping a real sync.
    internal init?(channelSerial: String) {
        let scanner = Scanner(string: channelSerial)
        scanner.charactersToBeSkipped = nil

        // Everything up to the first colon is the sequence id. We require a non-empty sequence id
        // so that the sequence-id comparison performed by RTO5a2/RTO5a3 is meaningful.
        // `scanUpToString` returns `nil` (rather than "") when there is nothing before the colon,
        // so the empty-sequence-id cases (":cursor", ":") are rejected here.
        guard let sequenceID = scanner.scanUpToString(":"), !sequenceID.isEmpty else {
            return nil
        }

        // There must be a colon separator; a serial with no colon (e.g. "sequence123") is rejected.
        guard scanner.scanString(":") != nil else {
            return nil
        }

        // Everything after the colon (if anything) is the cursor value. An empty cursor value marks
        // the end of the sequence (RTO5a4).
        let remainingString = channelSerial[scanner.currentIndex...]
        let cursorValue = remainingString.isEmpty ? nil : String(remainingString)

        self.sequenceID = sequenceID
        self.cursorValue = cursorValue
    }

    /// Whether this cursor represents the end of the sync sequence, per RTO5a4.
    internal var isEndOfSequence: Bool {
        cursorValue == nil
    }
}
