import Foundation

// swift-migration: original location NSArray+ARTFunctional.h, line 3 and NSArray+ARTFunctional.m, line 3
internal extension Array {
    
    // swift-migration: original location NSArray+ARTFunctional.h, line 5 and NSArray+ARTFunctional.m, line 5
    func artMap<T>(_ transform: (Element) -> T) -> [T] {
        return self.map(transform)
    }
    
    // swift-migration: original location NSArray+ARTFunctional.h, line 6 and NSArray+ARTFunctional.m, line 13
    func artFilter(_ predicate: (Element) -> Bool) -> [Element] {
        return self.filter(predicate)
    }
}