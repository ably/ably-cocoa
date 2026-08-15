// AblyLiveObjectsTesting: test-support module for the AblyLiveObjects plugin.
//
// This module hosts `@testable import AblyLiveObjects` extensions that expose
// internal state to AblyLiveObjectsTests, keeping the shipped sources free of
// test-only plumbing. See README.md for the dumb-accessor review rule and the
// recipe for adding a helper.
//
// The per-type internal-access seams live in `Internals/<Type>+TestsOnly.swift`
// (e.g. `InternalDefaultRealtimeObjects+TestsOnly.swift`); mocks, factories,
// loggers, and assertion helpers live in `Helpers/`. See README.md.

@testable import AblyLiveObjects
