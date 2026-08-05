// AblyLiveObjectsTesting: test-support module for the AblyLiveObjects plugin.
//
// This module hosts `@testable import AblyLiveObjects` extensions that expose
// internal state to AblyLiveObjectsTests, keeping the shipped sources free of
// test-only plumbing. See README.md for the dumb-accessor review rule and the
// recipe for adding a helper.
//
// The per-type helpers live in the sibling `<Type>+TestsOnly.swift` files in
// this directory (e.g. `InternalDefaultRealtimeObjects+TestsOnly.swift`).

@testable import AblyLiveObjects
