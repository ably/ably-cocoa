import Foundation
import Darwin

// swift-migration: original location ARTClientInformation.m, line 8
public let ARTClientInformationAgentNotVersioned = "ARTClientInformationAgentNotVersioned"

// swift-migration: original location ARTClientInformation+Private.h, line 5 and ARTClientInformation.m, line 9  
public let ARTClientInformation_libraryVersion = "1.2.44"

// swift-migration: original location ARTClientInformation.m, line 10
private let _libraryName = "ably-cocoa"

// NSOperatingSystemVersion has NSInteger as version components for some reason, so mitigate it here.
// swift-migration: original location ARTClientInformation.m, line 13
private func conformVersionComponent(_ component: Int) -> UInt32 {
    return (component < 0) ? 0 : UInt32(component)
}

// swift-migration: original location ARTClientInformation.h, line 13
public class ARTClientInformation: NSObject {
    
    // swift-migration: original location ARTClientInformation.h, line 15
    public override init() {
        fatalError("ARTClientInformation cannot be instantiated")
    }
    
    // swift-migration: original location ARTClientInformation.h, line 20 and ARTClientInformation.m, line 19
    /// Returns the default key-value entries that the Ably client library uses to identify itself, and the environment in which it's running, to the Ably service. Its keys are the names of the software components, and its values are their optional versions. The full list of keys that this method might return can be found [here](https://github.com/ably/ably-common/tree/main/protocol#agents). For example, users of the `ably-cocoa` client library can find out the library version by fetching the value for the `"ably-cocoa"` key from the return value of this method.
    public static var agents: [String: String] {
        var result: [String: String] = [:]
        
        result.merge(platformAgent) { (_, new) in new }
        result.merge(libraryAgent) { (_, new) in new }

        return result
    }

    // swift-migration: original location ARTClientInformation.h, line 29 and ARTClientInformation.m, line 28
    /// Returns the `Agent` library identifier. This method should only be used by Ably-authored SDKs.
    ///
    /// - Parameter additionalAgents: A set of additional entries for the `Agent` library identifier. Its keys are the names of the agents, and its values are their optional versions. Pass `ARTClientInformationAgentNotVersioned` as the dictionary value for an agent that does not have a version.
    /// - Returns: The `Agent` library identifier.
    public static func agentIdentifierWithAdditionalAgents(_ additionalAgents: [String: String]?) -> String {
        var agents = self.agents
        
        if let additionalAgents = additionalAgents {
            for (additionalAgentName, additionalAgentValue) in additionalAgents {
                agents[additionalAgentName] = additionalAgentValue
            }
        }
        
        return agentIdentifierForAgents(agents)
    }

    // swift-migration: original location ARTClientInformation+Private.h, line 13 and ARTClientInformation.m, line 38
    // The resulting string only includes the given agents; it does not insert any default agents.
    internal static func agentIdentifierForAgents(_ agents: [String: String]) -> String {
        var components: [String] = []

        // We sort the agent names so that we have a predictable order when testing.
        let sortedAgentNames = agents.keys.sorted()
        for name in sortedAgentNames {
            let version = agents[name]!
            if version == ARTClientInformationAgentNotVersioned {
                components.append(name)
            } else {
                components.append("\(name)/\(version)")
            }
        }
            
        return components.joined(separator: " ")
    }

    // swift-migration: original location ARTClientInformation.m, line 55
    private static var libraryAgent: [String: String] {
        return [_libraryName: ARTClientInformation_libraryVersion]
    }

    // swift-migration: original location ARTClientInformation+Private.h, line 9 and ARTClientInformation.m, line 59
    internal static func libraryAgentIdentifier() -> String {
        return agentIdentifierForAgents(libraryAgent)
    }

    // swift-migration: original location ARTClientInformation.m, line 63
    private static var platformAgent: [String: String] {
        guard let osName = osName else {
            return [:]
        }
        
        return [osName: osVersionString]
    }

    // swift-migration: original location ARTClientInformation+Private.h, line 10 and ARTClientInformation.m, line 73
    internal static func platformAgentIdentifier() -> String {
        return agentIdentifierForAgents(platformAgent)
    }

    // swift-migration: original location ARTClientInformation.m, line 77
    private static var osName: String? {
        #if os(iOS)
            return "iOS"
        #elseif os(tvOS)
            return "tvOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(macOS)
            return "macOS"
        #else
            return nil
        #endif
    }

    // swift-migration: original location ARTClientInformation.m, line 93
    private static var osVersionString: String {
        struct StaticStorage {
            static let versionString: String = {
                let version = ProcessInfo.processInfo.operatingSystemVersion
                return "\(conformVersionComponent(version.majorVersion)).\(conformVersionComponent(version.minorVersion)).\(conformVersionComponent(version.patchVersion))"
            }()
        }
        return StaticStorage.versionString
    }

    // swift-migration: original location ARTClientInformation.m, line 106
    // swift-migration: Complex C interop conversion required - Objective-C systemInfo.machine is char[256] array
    // which decays to char* automatically. Swift imports this as tuple (CChar, CChar, ...) with 256 elements.
    // Must use withUnsafeBytes to get pointer to tuple start, bindMemory to treat as CChar array, then
    // create Swift String from C string. Alternative String(cString: &systemInfo.machine.0) gives deprecation warning.
    internal static func deviceModel() -> String? {
        var systemInfo = utsname()
        if uname(&systemInfo) < 0 {
            return nil
        }
        return withUnsafeBytes(of: &systemInfo.machine) { bytes in
            return String(cString: bytes.bindMemory(to: CChar.self).baseAddress!)
        }
    }
}