import Ably
import Foundation

/// The `OBJECT_SYNC` sync cursor, as extracted from a `channelSerial` per RTO5a1 and RTO5a4.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, *)
internal struct SyncCursor {
    internal var sequenceID: String
    /// `nil` in the case where the objects sync sequence is complete (RTO5a4).
    internal var cursorValue: String?

    internal enum Error: Swift.Error {
        case channelSerialDoesNotMatchExpectedFormat(String)
    }

    /// Creates a `SyncCursor` from the `channelSerial` of an `OBJECT_SYNC` `ProtocolMessage`.
    ///
    /// Per RTO5a1–RTO5a5 the `channelSerial` is a two-part identifier `<sequence id>:<cursor value>`:
    /// everything up to the first colon is the sequence id (RTO5a1) and an empty cursor value marks the
    /// end of the sync sequence (RTO5a4).
    ///
    /// The specification does not define how to handle a `channelSerial` that lacks a colon separator
    /// (a spec clarification is to be raised). We surface that as a thrown ``Error`` so the caller decides what to do with it.
    internal init(channelSerial: String) throws(ARTErrorInfo) {
        let scanner = Scanner(string: channelSerial)
        scanner.charactersToBeSkipped = nil

        // Everything up to the first colon is the sequence id.
        let sequenceID = scanner.scanUpToString(":") ?? ""

        // There must be a colon separator; a serial with no colon (e.g. "sequence123") is malformed.
        guard scanner.scanString(":") != nil else {
            throw LiveObjectsError.other(Error.channelSerialDoesNotMatchExpectedFormat(channelSerial)).toARTErrorInfo()
        }

        // Everything after the colon (if anything) is the cursor value.
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
