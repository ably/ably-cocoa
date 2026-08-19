import Foundation

/// Shared constants for the Ably sandbox environments used by test provisioning.
public enum SandboxEnvironment {
    /// The Ably **nonprod sandbox** host — the `nonprod:sandbox` endpoint, resolved to a hostname.
    /// Keys provisioned against it are environment-scoped, so clients must point
    /// `restHost`/`realtimeHost` here. Single source of truth for every test tree that provisions
    /// against nonprod (the UTS integration tier and the LiveObjects tests).
    public static let nonprodHost = "sandbox.realtime.ably-nonprod.net"

    /// Per-request timeout for provisioning calls — fail fast instead of the 60s URLSession
    /// default, so a single stalled attempt doesn't dominate the retry budget of
    /// `withProvisioningRetries`.
    public static let provisioningTimeout: TimeInterval = 30
}
