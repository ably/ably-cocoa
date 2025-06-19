import Ably
@testable import AblyLiveObjects
import Testing

struct InternalErrorTests {
    @Test
    func artErrorInfo_toInternalError() {
        let errorInfo = ARTErrorInfo(domain: "foo", code: 3)

        // Check that we get errorInfo instead of the protocol extension on Swift.Error
        switch errorInfo.toInternalError() {
        case .errorInfo:
            break
        case .other:
            Issue.record("Expected .errorInfo")
        }
    }
}
