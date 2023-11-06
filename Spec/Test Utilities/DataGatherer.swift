import Foundation
import XCTest

/**
 A `DataGatherer` instance initiates a user-specified data-gathering activity, and provides a method for waiting until the activity submits some data.

 The `DataGatherer` instance only cares about the _first_ data that is submitted to it, and will ignore any subsequently-submitted data. When the gathered data has value semantics, this can simplify the implementation of tests, since they do not need to be so careful about making sure to stop their data-gathering process at the right time.
 */
class DataGatherer<T> {
    private let expectation: XCTestExpectation

    // The value that the initializer’s `gather` block passed to its `submit` argument.
    private var value: T?
    // Synchronises access to `value`.
    private let semaphore = DispatchSemaphore(value: 1)

    /**
     Initiates the data-gathering process specified by `gather`.

     - Parameters:
       - description: A human-readable description of the data-gathering process.
       - gather: A function which implements the data-gathering process. It should call the `submit` callback with the gathered data when ready. Subsequent calls to `submit` will have no effect. `submit` can be safely called from any thread.
     */
    init(description: String, gather: (_ submit: @escaping (T) -> Void) -> Void) {
        expectation = XCTestExpectation(description: description)
        gather(complete(withValue:))
    }

    enum Error: Swift.Error {
        case unexpectedResult(XCTWaiter.Result)
    }

    /**
     Waits for the initializer’s `gather` function to submit data and then returns the submitted data. If data has already been submitted then it is returned immediately. This method can be safely called from any thread.
     */
    func waitForData(timeout: TimeInterval) throws -> T {
        semaphore.wait()
        if let value = value {
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

    /**
     Waits for the initializer’s `gather` function to submit data and then returns the submitted data. If data has already been submitted then it is returned immediately. This method can be safely called from any thread.
     */
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
