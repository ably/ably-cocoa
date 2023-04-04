import Foundation
import XCTest

// why useful?

// - tests can tell it "here's the final data" and keep gathering further data after that if they want but it won't have any effect

// thread safe here

class DataGatherer<T> {
    private let expectation: XCTestExpectation

    // The value that the initializer’s `gather` block passed to its `submit` argument.
    private var value: T?
    // Synchronises access to `value`.
    private let semaphore = DispatchSemaphore(value: 1)

    init(description: String, gather: (_ submit: @escaping (T) -> Void) -> Void) {
        expectation = XCTestExpectation(description: description)
        gather(complete(withValue:))
    }

    enum Error: Swift.Error {
        case unexpectedResult(XCTWaiter.Result)
    }

    func waitForData(timeout: TimeInterval) throws -> T {
        semaphore.wait()
        if let value {
            semaphore.signal()
            return value
        }
        semaphore.signal()

        let waiter = XCTWaiter()
        let result = waiter.wait(for: [expectation], timeout: timeout)

        switch result {
        case .completed:
            let value: T
            semaphore.wait()
            value = self.value!
            semaphore.signal()
            return value
        default:
            throw Error.unexpectedResult(result)
        }
    }

    func waitForData(timeout: DispatchTimeInterval) throws -> T {
        return try waitForData(timeout: timeout.toTimeInterval())
    }

    private func complete(withValue value: T) {
        semaphore.wait()
        if self.value == nil {
            self.value = value
        }
        semaphore.signal()

        expectation.fulfill()
    }
}
