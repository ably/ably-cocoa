/// An infinite sequence of `Double` values in the range `0.8 ... 1`, suitable to be used for the return values of a mock instance of `JitterCoefficientGenerator`. All iterations of all instances of `StaticJitterCoefficients` return the same sequence of numbers.
struct StaticJitterCoefficients: Sequence {
    struct Iterator: IteratorProtocol {
        private let maxIndex = 10
        private var index = 0 // in range 0...maxIndex

        mutating func next() -> Double? {
            // Not a particularly thought-through implementation — just something that gives a non-monotonic sequence.

            let progress = Double(index) / Double(maxIndex) // in range 0...1
            index = (index + 1) % (maxIndex + 1)
            let direction = index.isMultiple(of: 2) ? 1 : -1
            return 0.9 + (Double(direction) * progress * 0.1)
        }
    }

    func makeIterator() -> Iterator {
        return Iterator()
    }
}
