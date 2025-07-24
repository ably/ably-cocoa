import Foundation

/// The `OBJECT_SYNC` sync cursor, as extracted from a `channelSerial` per RTO5a1 and RTO5a4.
internal struct SyncCursor {
    internal var sequenceID: String
    /// `nil` in the case where the objects sync sequence is complete (RTO5a4).
    internal var cursorValue: String?

    internal enum Error: Swift.Error {
        case channelSerialDoesNotMatchExpectedFormat(String)
    }

    /// Creates a `SyncCursor` from the `channelSerial` of an `OBJECT_SYNC` `ProtocolMessage`.
    internal init(channelSerial: String) throws(InternalError) {
        let scanner = Scanner(string: channelSerial)
        scanner.charactersToBeSkipped = nil

        // Get everything up to the colon as the sequence ID
        let sequenceID = scanner.scanUpToString(":") ?? ""

        // Check if we have a colon
        guard scanner.scanString(":") != nil else {
            throw Error.channelSerialDoesNotMatchExpectedFormat(channelSerial).toInternalError()
        }

        // Everything after the colon (if anything) is the cursor value
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
