/// An infinite sequence of `Double` values, providing the sequence of "backoff coefficients" defined by RTB1a. All iterations of all instances of `BackoffCoefficients` return the same sequence of numbers.
struct BackoffCoefficients: Sequence {
    struct Iterator: IteratorProtocol {
        private var retryNumber = 1

        mutating func next() -> Double? {
            let backoffCoefficient = Swift.min((Double(retryNumber) + 2) / 3.0, 2.0)
            retryNumber += 1
            return backoffCoefficient
        }
    }

    func makeIterator() -> Iterator {
        return Iterator()
    }
}
