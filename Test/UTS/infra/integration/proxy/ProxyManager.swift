// The proxy runs as a locally spawned child process, which requires `Foundation.Process` —
// unavailable on iOS/tvOS. Proxy integration tests are therefore macOS-only (on the simulator
// platforms this file compiles to nothing and the proxy suites are excluded by the same condition).
#if os(macOS)

import Foundation
import CryptoKit

/// Manages the lifecycle of the `uts-proxy` binary used for proxy integration tests.
///
/// Downloads the binary from GitHub releases on first use, caching it at
/// `~/.cache/uts-proxy/<version>/uts-proxy` (the same cache location ably-java uses, so the two
/// SDKs share a download). The download is serialised across OS processes by an exclusive `flock`
/// on `uts-proxy.lock`, and within this process by the actor's isolation. Note: only the *download*
/// is cross-process locked — process startup relies on the shared health check on `controlPort`,
/// so run proxy suites from **one test process at a time** (the same advisory ably-java's
/// ProxyManager makes for Gradle workers); concurrent runners could race to bind the control port
/// or reap a proxy the other is still using.
///
/// The spawned process does **not** die with its parent, so it is reaped by an `atexit` hook;
/// `stopProxy()` stops it explicitly.
///
/// To run against a locally built proxy instead of downloading a release, set the
/// `UTS_PROXY_LOCAL_PATH` environment variable to a local `uts-proxy` binary or a `.tar.gz`
/// distributive. When set, the download and checksum verification are skipped.
///
/// Call `try await ProxyManager.shared.ensureProxy()` in suite setup for every proxy integration
/// test suite — if the proxy is already healthy (e.g. started by a previous suite in the same run),
/// it is a no-op.
///
/// Mirrors ably-java's `infra/integration/proxy/ProxyManager.kt`. One deliberate difference: the
/// `.tar.gz` is extracted by spawning `/usr/bin/tar` (always present on macOS) instead of the
/// hand-rolled JDK-only tar reader ably-java needs.
actor ProxyManager {

    static let shared = ProxyManager()

    /// The proxy's control REST API port (shared by all sessions; data-plane ports are per-session).
    static let controlPort = 10100

    private static let proxyVersion = "v0.3.0"
    private static let versionBare = "0.3.0"
    private static let githubBase = "https://github.com/ably/uts-proxy/releases/download/\(proxyVersion)"

    /// SHA-256 checksums of the release archives (from the release's checksums.txt).
    private static let checksums: [String: String] = [
        "uts-proxy_\(versionBare)_darwin_amd64.tar.gz":
            "1355526543c3022f87efb7f564f55200b78edc68d84c7dba2e49f63429e3b788",
        "uts-proxy_\(versionBare)_darwin_arm64.tar.gz":
            "a948f99b7daf9b3bffff742f6405637d40a79947389309eed5f87e59026de9a5",
        "uts-proxy_\(versionBare)_linux_amd64.tar.gz":
            "de741ba21f3630fea4f59714d00585638d565005599ecd84179931eba248f280",
        "uts-proxy_\(versionBare)_linux_arm64.tar.gz":
            "15b5ca87c40c2c4ff350c94af1911cea0ad6be5a2d890ba41029bc4b8bc52c61",
    ]

    private static var archiveName: String {
        #if arch(arm64)
        let arch = "arm64"
        #elseif arch(x86_64)
        let arch = "amd64"
        #else
        #error("Unsupported architecture for uts-proxy")
        #endif
        return "uts-proxy_\(versionBare)_darwin_\(arch).tar.gz"
    }

    private static var cacheDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/uts-proxy/\(proxyVersion)", isDirectory: true)
    }

    private static var binaryURL: URL { cacheDir.appendingPathComponent("uts-proxy") }

    /// Where `UTS_PROXY_LOCAL_PATH` installs land — deliberately a *separate* file from the
    /// checksum-verified release at `binaryURL`, so a local build can never be mistaken for a
    /// verified cache hit by a later run without the override.
    private static var localBinaryURL: URL { cacheDir.appendingPathComponent("uts-proxy-local") }

    /// Optional path to a locally built `uts-proxy` binary or `.tar.gz` distributive, from the
    /// `UTS_PROXY_LOCAL_PATH` environment variable. When present, the release download + checksum
    /// check are bypassed (the artifact is installed to `localBinaryURL`, re-copied on every run).
    private static var localDistributive: String? {
        ProcessInfo.processInfo.environment["UTS_PROXY_LOCAL_PATH"].flatMap { $0.isEmpty ? nil : $0 }
    }

    // Short per-attempt timeout: /health is local, so a slow answer means "not up yet".
    private static let healthSession = makeURLSession(requestTimeout: 2)
    // Generous timeout for the release download.
    private static let downloadSession = makeURLSession(requestTimeout: 60)

    private var proxyProcess: Process?

    private init() {}

    /// Ensures the `uts-proxy` process is running on `controlPort`.
    ///
    /// If the proxy is already healthy (e.g. started by a previous test suite in the same run, or
    /// launched manually), this is a no-op. Otherwise it downloads + verifies the binary and starts
    /// the process.
    ///
    /// - Parameter timeout: Maximum wall-clock seconds to wait for the process to become healthy.
    func ensureProxy(timeout: TimeInterval = 15) async throws {
        if await Self.isHealthy() { return }
        let binary = try await Self.ensureBinary()

        let process = Process()
        process.executableURL = binary
        process.arguments = ["--port", "\(Self.controlPort)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        proxyProcess = process
        ProxyProcessReaper.shared.register(process)

        try await waitForHealth(timeout: timeout)
    }

    /// Stops the shared proxy process if this test run started one.
    ///
    /// The process is normally left running for the lifetime of the test run (it is reused across
    /// suites) and reaped by the `atexit` hook. This method is exposed for explicit teardown.
    func stopProxy() {
        proxyProcess?.terminate()
        proxyProcess = nil
    }

    // MARK: - Internal

    static func isHealthy() async -> Bool {
        let url = URL(string: "http://localhost:\(controlPort)/health")!
        let result = try? await httpRequest(URLRequest(url: url), session: healthSession)
        return result?.status == 200
    }

    private func waitForHealth(timeout: TimeInterval) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        do {
            while Date() < deadline {
                if await Self.isHealthy() { return }
                try await Task.sleep(nanoseconds: 200_000_000)
            }
        } catch {
            // Task cancelled — reap the process we just spawned and propagate.
            proxyProcess?.terminate()
            proxyProcess = nil
            throw error
        }
        proxyProcess?.terminate()
        proxyProcess = nil
        throw HTTPError("uts-proxy did not become healthy within \(timeout)s")
    }

    /// Ensures the binary is present in the cache, downloading and extracting if needed.
    /// Returns the binary to launch: the verified release, or the separate local install when
    /// `UTS_PROXY_LOCAL_PATH` is set.
    private static func ensureBinary() async throws -> URL {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        if let local = localDistributive {
            try installLocalDistributive(local)
            return localBinaryURL
        }

        // flock serialises the download across concurrently launched test processes.
        let lockURL = cacheDir.appendingPathComponent("uts-proxy.lock")
        let lockFd = open(lockURL.path, O_CREAT | O_WRONLY, 0o644)
        guard lockFd >= 0 else { throw HTTPError("Cannot open \(lockURL.path) for locking") }
        defer { close(lockFd) }
        flock(lockFd, LOCK_EX)
        defer { flock(lockFd, LOCK_UN) }

        // The archive (not the extracted binary) is checksum-verified at download time, and the
        // cache dir is keyed on the version, so a present+executable binary is a hit.
        if fileManager.isExecutableFile(atPath: binaryURL.path) {
            return binaryURL
        }

        let archiveBytes = try await downloadArchive()
        try verifyChecksum(archiveBytes)
        try extractBinary(fromArchiveBytes: archiveBytes, to: binaryURL)
        return binaryURL
    }

    /// Installs a locally provided distributive into the cache, skipping download + checksum.
    /// The path may be a raw `uts-proxy` binary or a `.tar.gz` archive containing one.
    private static func installLocalDistributive(_ path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw HTTPError("Local uts-proxy distributive not found at \(path)")
        }
        FileHandle.standardError.write(Data("Using local uts-proxy distributive: \(path)\n".utf8))
        if path.hasSuffix(".tar.gz") {
            try extractBinary(fromArchiveBytes: Data(contentsOf: URL(fileURLWithPath: path)), to: localBinaryURL)
        } else {
            try? FileManager.default.removeItem(at: localBinaryURL)
            try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: localBinaryURL)
            try makeExecutable(localBinaryURL)
        }
    }

    private static func downloadArchive() async throws -> Data {
        FileHandle.standardError.write(Data("Downloading uts-proxy \(proxyVersion) (\(archiveName))…\n".utf8))
        // GitHub release downloads 302-redirect to the asset CDN; URLSession follows by default.
        let url = URL(string: "\(githubBase)/\(archiveName)")!
        let (data, status) = try await httpRequest(URLRequest(url: url), session: downloadSession)
        guard status == 200 else {
            throw HTTPError("Failed to download uts-proxy from \(url): HTTP \(status)")
        }
        return data
    }

    private static func verifyChecksum(_ bytes: Data) throws {
        guard let expected = checksums[archiveName] else {
            throw HTTPError("No checksum for \(archiveName) — unsupported platform/arch")
        }
        let actual = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        guard actual == expected else {
            throw HTTPError("Checksum mismatch for \(archiveName): expected \(expected), got \(actual)")
        }
    }

    /// Extracts the `uts-proxy` binary from the `.tar.gz` bytes to `destination`, using the
    /// system `tar`.
    private static func extractBinary(fromArchiveBytes bytes: Data, to destination: URL) throws {
        let fileManager = FileManager.default
        let stagingDir = fileManager.temporaryDirectory
            .appendingPathComponent("uts-proxy-extract-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: stagingDir) }

        let archiveURL = stagingDir.appendingPathComponent(archiveName)
        try bytes.write(to: archiveURL)

        let tar = Process()
        tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tar.arguments = ["-xzf", archiveURL.path, "-C", stagingDir.path]
        try tar.run()
        tar.waitUntilExit()
        guard tar.terminationStatus == 0 else {
            throw HTTPError("tar failed to extract \(archiveName) (exit \(tar.terminationStatus))")
        }

        let extracted = stagingDir.appendingPathComponent("uts-proxy")
        guard fileManager.fileExists(atPath: extracted.path) else {
            throw HTTPError("uts-proxy binary not found in archive '\(archiveName)'")
        }
        try? fileManager.removeItem(at: destination)
        try fileManager.moveItem(at: extracted, to: destination)
        try makeExecutable(destination)
    }

    private static func makeExecutable(_ url: URL) throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}

/// Kills any proxy process this test run spawned when the test process exits — a `Process` child
/// does not die with its parent. Registered via `atexit` (the closure must not capture anything,
/// so it reaches the reaper through the `shared` global).
private final class ProxyProcessReaper: @unchecked Sendable {
    static let shared = ProxyProcessReaper()

    private let lock = NSLock()
    private var processes: [Process] = []

    private init() {
        atexit { ProxyProcessReaper.shared.killAll() }
    }

    func register(_ process: Process) {
        lock.lock()
        processes.append(process)
        lock.unlock()
    }

    private func killAll() {
        lock.lock()
        let toKill = processes
        processes.removeAll()
        lock.unlock()
        for process in toKill where process.isRunning {
            process.terminate()
        }
    }
}

#endif
