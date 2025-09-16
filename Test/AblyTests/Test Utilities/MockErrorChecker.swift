@testable import AblySwift

class MockErrorChecker: ErrorChecker {
    var isTokenError: Bool!

    func isTokenError(_ errorInfo: ARTErrorInfo) -> Bool {
        return isTokenError
    }
}
