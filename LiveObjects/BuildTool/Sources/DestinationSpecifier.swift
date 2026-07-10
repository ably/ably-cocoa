import Foundation

enum DestinationSpecifier {
    case platform(String)
    case deviceID(String)

    var xcodebuildArgument: String {
        switch self {
        case let .platform(platform):
            "platform=\(platform)"
        case let .deviceID(deviceID):
            "id=\(deviceID)"
        }
    }
}
