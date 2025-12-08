import Foundation

enum Error: Swift.Error {
    case terminatedWithExitCode(Int32)
    case simulatorLookupFailed(message: String)
}
