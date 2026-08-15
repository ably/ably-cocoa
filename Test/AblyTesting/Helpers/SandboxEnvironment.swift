/// Shared constants for the Ably sandbox environments used by test provisioning.
public enum SandboxEnvironment {
    /// The Ably **nonprod sandbox** host — the `nonprod:sandbox` endpoint, resolved to a hostname.
    /// Keys provisioned against it are environment-scoped, so clients must point
    /// `restHost`/`realtimeHost` here. Single source of truth for every test tree that provisions
    /// against nonprod (the UTS integration tier and the LiveObjects tests).
    public static let nonprodHost = "sandbox.realtime.ably-nonprod.net"
}
