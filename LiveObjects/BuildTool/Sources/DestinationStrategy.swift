import Foundation

enum DestinationStrategy {
    case fixed(platform: String)
    case lookup(destinationPredicate: DestinationPredicate)
}
