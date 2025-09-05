import Foundation

// MARK: - Array Extensions

extension Array {
    /// Maps elements using the provided transform function
    func artMap<T>(_ transform: (Element) -> T) -> [T] {
        return self.map(transform)
    }
    
    /// Filters elements using the provided predicate
    func artFilter(_ predicate: (Element) -> Bool) -> [Element] {
        return self.filter(predicate)
    }
}

// MARK: - Array Queue Extensions

extension Array {
    /// Adds an element to the end (enqueue)
    mutating func art_enqueue(_ element: Element) {
        append(element)
    }
    
    /// Removes and returns the first element (dequeue)
    mutating func art_dequeue() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
    
    /// Returns the first element without removing it (peek)
    func art_peek() -> Element? {
        return first
    }
}