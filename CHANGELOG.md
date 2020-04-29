# Change Log

## [1.1.23](https://github.com/ably/ably-cocoa/tree/1.1.23)

[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.22...1.1.23)

**Implemented enhancements:**

- Remove queueing messages in a channel-level queue [\#894](https://github.com/ably/ably-cocoa/issues/894)

**Fixed bugs:**

- lib fails all the user's channels on transition to connecting/disconnected if queueMessages is disabled? [\#1004](https://github.com/ably/ably-cocoa/issues/1004)

**Closed issues:**

- Implement push spec update https://github.com/ably/docs/pull/710 [\#876](https://github.com/ably/ably-cocoa/issues/876)

**Merged pull requests:**

- Refine release procedure [\#1014](https://github.com/ably/ably-cocoa/pull/1014) ([QuintinWillison](https://github.com/QuintinWillison))
- Fix 'queueMessages' expected behaviour [\#1005](https://github.com/ably/ably-cocoa/pull/1005) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.22](https://github.com/ably/ably-cocoa/tree/1.1.22)

[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.21...1.1.22)

**Fixed bugs:**

- Custom logger not working? [\#1010](https://github.com/ably/ably-cocoa/issues/1010)

**Closed issues:**

- request\_id in REST requests [\#1001](https://github.com/ably/ably-cocoa/issues/1001)
- Memory leak issues preventing destroying client [\#997](https://github.com/ably/ably-cocoa/issues/997)

**Merged pull requests:**

- Test suite: keep channel name prefix for current ClientOptions while calling 'setupOptions' and other improvements [\#1009](https://github.com/ably/ably-cocoa/pull/1009) ([ricardopereira](https://github.com/ricardopereira))
- Avoid leak from user incorrectly holding to authCallback's callback. [\#1000](https://github.com/ably/ably-cocoa/pull/1000) ([tcard](https://github.com/tcard))
- Allow customers to subclass ARTLog [\#1011](https://github.com/ably/ably-cocoa/pull/1011) ([QuintinWillison](https://github.com/QuintinWillison))

## [1.1.21](https://github.com/ably/ably-cocoa/tree/1.1.21)

[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.20...1.1.21)

**Merged pull requests:**

- Fix Objective-C namespace collisions [\#1006](https://github.com/ably/ably-cocoa/pull/1006) ([SlaunchaMan](https://github.com/SlaunchaMan))
- Fix strong ref cycle: Rest.push and Rest.push.admin \<-\> Rest. [\#999](https://github.com/ably/ably-cocoa/pull/999) ([tcard](https://github.com/tcard))

## [1.1.20](https://github.com/ably/ably-cocoa/tree/1.1.20)

[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.19...1.1.20)

**Changes:**

- Support build with Xcode 10 ([23b235c](https://github.com/ably/ably-cocoa/commit/23b235cac8908ba69096dd95f4e47ae3cae8a484)) - brings in [SocketRocket #5](https://github.com/ably-forks/SocketRocket/pull/5)

## [1.1.19](https://github.com/ably/ably-cocoa/tree/1.1.19)

[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.18...1.1.19)

**Fixed bugs:**

- Old push state AfterRegistrationUpdateFailed needs migration [\#993](https://github.com/ably/ably-cocoa/issues/993)

**Closed issues:**

- Auth token refresh misses when macOS is sleeping [\#984](https://github.com/ably/ably-cocoa/issues/984)

**Merged pull requests:**

- Push: Fix activate\(\) behavior while syncing device. [\#995](https://github.com/ably/ably-cocoa/pull/995) ([tcard](https://github.com/tcard))
- Migrate persisted AfterRegistrationUpdateFailed to ...SyncFailed. [\#994](https://github.com/ably/ably-cocoa/pull/994) ([tcard](https://github.com/tcard))
- Use tests dispatch queue, not main, to POST /apps. [\#991](https://github.com/ably/ably-cocoa/pull/991) ([tcard](https://github.com/tcard))
- Update SocketRocket dependency [\#990](https://github.com/ably/ably-cocoa/pull/990) ([ricardopereira](https://github.com/ricardopereira))
- Document development flow [\#989](https://github.com/ably/ably-cocoa/pull/989) ([QuintinWillison](https://github.com/QuintinWillison))
- Second Attempt to Update KSCrash dependency [\#988](https://github.com/ably/ably-cocoa/pull/988) ([QuintinWillison](https://github.com/QuintinWillison))
- Fix handling of token error when first connecting. [\#986](https://github.com/ably/ably-cocoa/pull/986) ([tcard](https://github.com/tcard))
- Update KSCrash dependency [\#981](https://github.com/ably/ably-cocoa/pull/981) ([QuintinWillison](https://github.com/QuintinWillison))
- Fix bad merge in README. [\#980](https://github.com/ably/ably-cocoa/pull/980) ([tcard](https://github.com/tcard))
- Validate and sync when activating push for registered device [\#974](https://github.com/ably/ably-cocoa/pull/974) ([tcard](https://github.com/tcard))
- Update ably-ios references to ably-cocoa [\#954](https://github.com/ably/ably-cocoa/pull/954) ([tcard](https://github.com/tcard))

## [1.1.18](https://github.com/ably/ably-cocoa/tree/1.1.18)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.17...1.1.18)

**Fixed bugs:**

- Result of internet-up.ably-realtime.com is ignored [\#952](https://github.com/ably/ably-cocoa/issues/952)
- Realtime suspended connection retrial using wrong timeout [\#913](https://github.com/ably/ably-cocoa/issues/913)

**Closed issues:**

- Remove develop branch [\#969](https://github.com/ably/ably-cocoa/issues/969)
- Flaky test: RTP2f \(incoming LEAVE while SYNCing\) [\#938](https://github.com/ably/ably-cocoa/issues/938)
- Flaky test: RTN17\* \(fallback hosts\) [\#931](https://github.com/ably/ably-cocoa/issues/931)

**Merged pull requests:**

- Remove redundant direct calls to push delegate callbacks [\#975](https://github.com/ably/ably-cocoa/pull/975) ([tcard](https://github.com/tcard))
- Simplify hooks on RTP2f test [\#963](https://github.com/ably/ably-cocoa/pull/963) ([tcard](https://github.com/tcard))
- Fix internet-up.ably-realtime.com checks [\#961](https://github.com/ably/ably-cocoa/pull/961) ([tcard](https://github.com/tcard))
- Fix connection SUSPENDED timeout [\#917](https://github.com/ably/ably-cocoa/pull/917) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.17](https://github.com/ably/ably-cocoa/tree/1.1.17)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.16...1.1.17)

**Merged pull requests:**

- Remove push state machine singleton [\#972](https://github.com/ably/ably-cocoa/pull/972) ([tcard](https://github.com/tcard))
- Add clarification to release process: document --since-tag effects [\#971](https://github.com/ably/ably-cocoa/pull/971) ([tcard](https://github.com/tcard))

## [1.1.16](https://github.com/ably/ably-cocoa/tree/1.1.16)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.15...1.1.16)

**Fixed bugs:**

- Cannot compile Objective-C++ file if Ably headers included [\#964](https://github.com/ably/ably-cocoa/issues/964)
- Realtime Channel endless loop: suspended \> attached \> suspended [\#881](https://github.com/ably/ably-cocoa/issues/881)

**Closed issues:**

- Flaky test: RTN5 \(basic operations should work simultaneously\) [\#934](https://github.com/ably/ably-cocoa/issues/934)

**Merged pull requests:**

- If waiting for push device details and got them persisted, re-emit them. [\#967](https://github.com/ably/ably-cocoa/pull/967) ([tcard](https://github.com/tcard))
- Update msgpack \(fix CocoaPod warnings\) [\#962](https://github.com/ably/ably-cocoa/pull/962) ([ricardopereira](https://github.com/ricardopereira))
- Alleviate RTN5 flakiness [\#957](https://github.com/ably/ably-cocoa/pull/957) ([tcard](https://github.com/tcard))
- Fix SUSPENDED channel reattach [\#909](https://github.com/ably/ably-cocoa/pull/909) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.15](https://github.com/ably/ably-cocoa/tree/1.1.15) (2019-12-23)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.14...1.1.15)

**Merged pull requests:**

- KSCrash fork has been renamed to KSCrashAblyFork 
 [\#955](https://github.com/ably/ably-cocoa/pull/955) ([ricardopereira](https://github.com/ricardopereira))
- Update msgpack to v0.3 [\#951](https://github.com/ably/ably-cocoa/pull/951) ([ricardopereira](https://github.com/ricardopereira))
- Simplify random fallback host selection [\#953](https://github.com/ably/ably-cocoa/pull/953) ([tcard](https://github.com/tcard))

## [1.1.14](https://github.com/ably/ably-cocoa/tree/1.1.14) (2019-12-16)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.13...1.1.14)

**Fixed bugs:**

- iOS Incompatible library version crash - DYLIB_COMPATIBILITY_VERSION vs DYLIB_CURRENT_VERSION [\#946](https://github.com/ably/ably-cocoa/issues/946)

## [1.1.13](https://github.com/ably/ably-cocoa/tree/1.1.13) (2019-12-09)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.12...1.1.13)

**Fixed bugs:**

- OS Network Reachability sometimes doesn't detect network state changes [\#908](https://github.com/ably/ably-cocoa/issues/908)
- Using a clientId should no longer be forcing token auth in the 1.1 spec [\#849](https://github.com/ably/ably-cocoa/issues/849)
- Move channels to FAILED only after their iterator is done.  [\#920](https://github.com/ably/ably-cocoa/pull/920) ([tcard](https://github.com/tcard))
- Copy channels for public iterate\(\) on internal queue. [\#919](https://github.com/ably/ably-cocoa/pull/919) ([tcard](https://github.com/tcard))

**Closed issues:**

- Queuing messages before attach can lead to out-of-order publishing [\#926](https://github.com/ably/ably-cocoa/issues/926)
- Channels mutated-while-enumerated crash [\#918](https://github.com/ably/ably-cocoa/issues/918)
- Xcode 11 warnings [\#905](https://github.com/ably/ably-cocoa/issues/905)

**Merged pull requests:**

- Make ARTRealtimeChannel.publish thread-safe [\#929](https://github.com/ably/ably-cocoa/pull/929) ([tcard](https://github.com/tcard))
- Extract duplicate code from ARTChannel.publish methods [\#928](https://github.com/ably/ably-cocoa/pull/928) ([tcard](https://github.com/tcard))
- Set logLevel=verbose every time setupOptions is called with debug=true [\#927](https://github.com/ably/ably-cocoa/pull/927) ([tcard](https://github.com/tcard))
- Don't assert on error messages. [\#925](https://github.com/ably/ably-cocoa/pull/925) ([tcard](https://github.com/tcard))
- Prevent mutate-channels-while-iterating for suspend too. [\#922](https://github.com/ably/ably-cocoa/pull/922) ([tcard](https://github.com/tcard))
- Soak test [\#916](https://github.com/ably/ably-cocoa/pull/916) ([tcard](https://github.com/tcard))
- Fix Network Reachability: instance not found for target [\#910](https://github.com/ably/ably-cocoa/pull/910) ([ricardopereira](https://github.com/ricardopereira))
- Fix Xcode 11 new warnings [\#907](https://github.com/ably/ably-cocoa/pull/907) ([ricardopereira](https://github.com/ricardopereira))
- README: update the release process [\#906](https://github.com/ably/ably-cocoa/pull/906) ([ricardopereira](https://github.com/ricardopereira))
- Carthage: fix public header imports [\#902](https://github.com/ably/ably-cocoa/pull/902) ([ricardopereira](https://github.com/ricardopereira))
- Should not force token auth when clientId is set [\#898](https://github.com/ably/ably-cocoa/pull/898) ([ricardopereira](https://github.com/ricardopereira))
- Improve error and debug messages [\#895](https://github.com/ably/ably-cocoa/pull/895) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.12](https://github.com/ably/ably-cocoa/tree/1.1.12) (2019-10-03)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.10...1.1.12)

**Fixed bugs:**

 - Push token: replace `NSData.description` usage [\#889](https://github.com/ably/ably-cocoa/issues/889)

**Merged pull requests:**

 - Replace `NSData.description` to stringify device tokens correctly [\#893](https://github.com/ably/ably-cocoa/issues/893) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.11-beta.1](https://github.com/ably/ably-cocoa/tree/1.1.11-beta.1) (2019-09-20)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.10...1.1.11-beta.1)

**Fixed bugs:**

 - Push token: replace `NSData.description` usage [\#889](https://github.com/ably/ably-cocoa/issues/889)
 - `PushChannel.subscribe` should not call the callback in the internal queue [\#862](https://github.com/ably/ably-cocoa/issues/862)
 - Crash in ARTPush: "dispatch_sync called on queue already owned by current thread" [\#888](https://github.com/ably/ably-cocoa/issues/888)
 - Push is using the system `NSLog` directly instead of the `ARTLogger` [\#896](https://github.com/ably/ably-cocoa/issues/896)

- **Tentative fix of:** Crash on creating weak ref to deallocating object [\#879](https://github.com/ably/ably-cocoa/issues/879)

**Merged pull requests:**

 - Push: replace system `NSLog` with internal `ARTLogger` [\#896](https://github.com/ably/ably-cocoa/issues/896) ([ricardopereira](https://github.com/ricardopereira))
 - Replace `NSData.description` to stringify device tokens correctly [\#893](https://github.com/ably/ably-cocoa/issues/893) ([ricardopereira](https://github.com/ricardopereira))
 - Push: fix crash "_dispatch_sync called on queue already owned by current thread_" [\#888](https://github.com/ably/ably-cocoa/issues/888) ([ricardopereira](https://github.com/ricardopereira))
 - Push: `PushChannel.subscribe` should not call the callback in the internal queue [\#862](https://github.com/ably/ably-cocoa/issues/862) ([ricardopereira](https://github.com/ricardopereira))
- Split in public and internal objects [\#882](https://github.com/ably/ably-cocoa/pull/882) ([tcard](https://github.com/tcard ))

## [1.1.11-beta.0](https://github.com/ably/ably-cocoa/tree/1.1.11-beta.0) (2019-08-27)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.10...1.1.11-beta.0)

**Fixed bugs:**

- **Tentative fix of:** Crash on creating weak ref to deallocating object [\#879](https://github.com/ably/ably-cocoa/issues/879)

**Merged pull requests:**

- Split in public and internal objects [\#882](https://github.com/ably/ably-cocoa/pull/882) ([tcard](https://github.com/tcard ))

## [1.1.10](https://github.com/ably/ably-cocoa/tree/1.1.10) (2019-07-29)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.9...1.1.10)

**Fixed bugs:**

- Push device registration omits `clientId` [\#877](https://github.com/ably/ably-cocoa/issues/877)

**Merged pull requests:**

- Update `LocalDevice.clientId` [\#874](https://github.com/ably/ably-cocoa/pull/874) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.9](https://github.com/ably/ably-cocoa/tree/1.1.9) (2019-07-12)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.8...1.1.9)

**Fixed bugs:**

- Push deactivate on an app is failing with `push-subscribe` permissions [\#873](https://github.com/ably/ably-cocoa/issues/873)

**Merged pull requests:**

- Delete device registration should not use the general-purpose endpoint [\#871](https://github.com/ably/ably-cocoa/pull/871) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.8](https://github.com/ably/ably-cocoa/tree/1.1.8) (2019-07-03)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.7...1.1.8)

**Fixed bugs:**

- Push deactivate/activate sequence results in stopped notifications [\#863](https://github.com/ably/ably-cocoa/issues/863)
- Library apparently interpreting the `connectionStateTtl` with incorrect units [\#866](https://github.com/ably/ably-cocoa/issues/866)

**Merged pull requests:**

- Push Device Update Registration: fix request authentication [\#867](https://github.com/ably/ably-cocoa/pull/867) ([ricardopereira](https://github.com/ricardopereira))
- Fix consecutive Authorizations [\#833](https://github.com/ably/ably-cocoa/pull/833) ([ricardopereira](https://github.com/ricardopereira))
- Fix milliseconds conversions [\#869](https://github.com/ably/ably-cocoa/pull/869) ([ricardopereira](https://github.com/ricardopereira))
- Tests using `echo.ably.io` were failing intermittently with "Request mac does not match" [\#868](https://github.com/ably/ably-cocoa/pull/868) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.7](https://github.com/ably/ably-cocoa/tree/1.1.7) (2019-06-25)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.6...1.1.7)

**Fixed bugs:**

- Push deactivate/activate sequence results in stopped notifications [\#863](https://github.com/ably/ably-cocoa/issues/863)

**Merged pull requests:**

- Fix Push Activation State Machine: WaitingForRegistrationUpdate bad state [\#864](https://github.com/ably/ably-cocoa/pull/858) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.6](https://github.com/ably/ably-cocoa/tree/1.1.6) (2019-06-12)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.5...1.1.6)

**Fixed bugs:**

- Lexical or Preprocessor Issue: 'SRWebSocket.h' file not found [\#840](https://github.com/ably/ably-cocoa/issues/840)
- KSCrashAblyFork ksthread_getQueueName [\#846](https://github.com/ably/ably-cocoa/issues/846)

**Closed issues:**

- Fix Travis CI (iOS 9 build is failing) [\#856](https://github.com/ably/ably-cocoa/issues/856)

**Merged pull requests:**

- Update KSCrash and SocketRocket [\#858](https://github.com/ably/ably-cocoa/pull/858) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.5](https://github.com/ably/ably-cocoa/tree/1.1.5) (2019-05-23)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.4...1.1.5)

**Implemented enhancements:**

- Swift 5 / Xcode 10.2 [\#838](https://github.com/ably/ably-cocoa/issues/838)

**Fixed bugs:**

- Issue reported in iOS push tutorial [\#850](https://github.com/ably/ably-cocoa/issues/850)

**Closed issues:**

- Expose `Auth.tokenDetails` [\#852](https://github.com/ably/ably-cocoa/issues/852)
- Improve handling of clock skew [\#834](https://github.com/ably/ably-cocoa/issues/834)
- `my-members` presenceMap requirement change for 1.1 [\#737](https://github.com/ably/ably-cocoa/issues/737)

**Merged pull requests:**

- Swift 5 (Xcode 10.2) [\#841](https://github.com/ably/ably-cocoa/pull/841) ([ricardopereira](https://github.com/ricardopereira))
- RSA11 [\#853](https://github.com/ably/ably-cocoa/pull/853) ([ricardopereira](https://github.com/ricardopereira))
- Push header docs [\#827](https://github.com/ably/ably-cocoa/pull/827) ([ricardopereira](https://github.com/ricardopereira))
- Fix Push Update Device Registration [\#851](https://github.com/ably/ably-cocoa/pull/851) ([ricardopereira](https://github.com/ricardopereira))
- RTP17b [\#835](https://github.com/ably/ably-cocoa/pull/835) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.4](https://github.com/ably/ably-cocoa/tree/1.1.4) (2019-05-07)
[Full Changelog](https://github.com/ably/ably-cocoa/compare/1.1.3...1.1.4)

**Implemented enhancements:**

- Add idempotent REST publishing [\#749](https://github.com/ably/ably-cocoa/issues/749)

**Fixed bugs:**

- Default token params should not include a capabilities member [\#576](https://github.com/ably/ably-cocoa/issues/576)
- Unsubscribe on channel enumeration causing crash [\#842](https://github.com/ably/ably-cocoa/issues/842)

**Closed issues:**

- Address msgpack warnings [\#689](https://github.com/ably/ably-cocoa/issues/689)

**Merged pull requests:**

- Fix RTN16f [\#845](https://github.com/ably/ably-cocoa/pull/845) ([ricardopereira](https://github.com/ricardopereira))
- Idempotent Rest Publishing [\#786](https://github.com/ably/ably-cocoa/pull/786) ([ricardopereira](https://github.com/ricardopereira))
- RSL1j [\#784](https://github.com/ably/ably-cocoa/pull/784) ([ricardopereira](https://github.com/ricardopereira))
- RSA4b1 [\#836](https://github.com/ably/ably-cocoa/pull/836) ([ricardopereira](https://github.com/ricardopereira))
- Fix Channel.subscribe onAttachCallback [\#844](https://github.com/ably/ably-cocoa/pull/844) ([ricardopereira](https://github.com/ricardopereira))
- Timestamp should not be generated in the client [\#831](https://github.com/ably/ably-cocoa/pull/831) ([ricardopereira](https://github.com/ricardopereira))
- Fix URL query encoding of Capability and Timestamp fields [\#830](https://github.com/ably/ably-cocoa/pull/830) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSA6 [\#829](https://github.com/ably/ably-cocoa/pull/829) ([ricardopereira](https://github.com/ricardopereira))
- Push State Machine: main thread sometimes gets stuck when accessing Local Device [\#826](https://github.com/ably/ably-cocoa/pull/826) ([ricardopereira](https://github.com/ricardopereira))
- asd [\#784]() ([ricardopereira](https://github.com/ricardopereira))

## [1.1.3](https://github.com/ably/ably-ios/tree/1.1.3) (2019-01-10)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.1.2...1.1.3)

**Merged pull requests:**

- Multi platform [\#823](https://github.com/ably/ably-ios/pull/823) ([ricardopereira](https://github.com/ricardopereira))
- TV support [\#821](https://github.com/ably/ably-ios/pull/821) ([ricardopereira](https://github.com/ricardopereira))
- Makefile \(and fix version bump\) [\#820](https://github.com/ably/ably-ios/pull/820) ([ricardopereira](https://github.com/ricardopereira))
- Mac support [\#817](https://github.com/ably/ably-ios/pull/817) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.2](https://github.com/ably/ably-ios/tree/1.1.2) (2018-11-06)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.1.1...1.1.2)

**Implemented enhancements:**

- Replace NSURL with URL in Swift code [\#794](https://github.com/ably/ably-ios/issues/794)
- Address SocketRocket warnings [\#688](https://github.com/ably/ably-ios/issues/688)

**Fixed bugs:**

- Unable to submit to AppStore [\#803](https://github.com/ably/ably-ios/issues/803)
- After connection recovery, the client resets msgSerial [\#799](https://github.com/ably/ably-ios/issues/799)
- Investigate implementation of RTN15a [\#727](https://github.com/ably/ably-ios/issues/727)
- SocketRocket - missing required key when submitting to the App Store [\#701](https://github.com/ably/ably-ios/issues/701)

**Closed issues:**

- Issue while subscribe device for Push Notifications [\#796](https://github.com/ably/ably-ios/issues/796)
- Potential code that could stall some CI executions [\#758](https://github.com/ably/ably-ios/issues/758)
- Check use of `dev:push-device-auth` environment [\#781](https://github.com/ably/ably-ios/issues/781)
- Check behavior of RTN15h\* [\#731](https://github.com/ably/ably-ios/issues/731)
- Investigate implementation of RTN14b [\#730](https://github.com/ably/ably-ios/issues/730)

**Merged pull requests:**

- Update to Xcode10 Swift 4.2 [\#813](https://github.com/ably/ably-ios/pull/813) ([funkyboy](https://github.com/funkyboy))
- Xcode 10 minimal support [\#812](https://github.com/ably/ably-ios/pull/812) ([ricardopereira](https://github.com/ricardopereira))
- Fix Realtime clients creation outside the `it` method scope [\#811](https://github.com/ably/ably-ios/pull/811) ([ricardopereira](https://github.com/ricardopereira))
- Add RTL6d2 [\#806](https://github.com/ably/ably-ios/pull/806) ([funkyboy](https://github.com/funkyboy))
- SocketRocketAblyFork [\#808](https://github.com/ably/ably-ios/pull/808) ([ricardopereira](https://github.com/ricardopereira))
- Fix RTL6d1 [\#807](https://github.com/ably/ably-ios/pull/807) ([funkyboy](https://github.com/funkyboy))
- Add rtl6d1 [\#802](https://github.com/ably/ably-ios/pull/802) ([funkyboy](https://github.com/funkyboy))
- RTN16f [\#801](https://github.com/ably/ably-ios/pull/801) ([ricardopereira](https://github.com/ricardopereira))
- Update RTN16b [\#800](https://github.com/ably/ably-ios/pull/800) ([ricardopereira](https://github.com/ricardopereira))
- Add test for RTN15h1 [\#798](https://github.com/ably/ably-ios/pull/798) ([funkyboy](https://github.com/funkyboy))
- NSURL -\> URL in Swift code [\#797](https://github.com/ably/ably-ios/pull/797) ([funkyboy](https://github.com/funkyboy))
- Add TR3\* [\#793](https://github.com/ably/ably-ios/pull/793) ([funkyboy](https://github.com/funkyboy))
- Add ref to RTN23a [\#792](https://github.com/ably/ably-ios/pull/792) ([funkyboy](https://github.com/funkyboy))
- Improve RTN14b test [\#791](https://github.com/ably/ably-ios/pull/791) ([funkyboy](https://github.com/funkyboy))
- Reactivate and fix RTP17 tests [\#790](https://github.com/ably/ably-ios/pull/790) ([funkyboy](https://github.com/funkyboy))
- Add RTN15a [\#789](https://github.com/ably/ably-ios/pull/789) ([funkyboy](https://github.com/funkyboy))
- Fix RSL1b [\#788](https://github.com/ably/ably-ios/pull/788) ([ricardopereira](https://github.com/ricardopereira))
- Move RSL1i to RestClientChannel file [\#785](https://github.com/ably/ably-ios/pull/785) ([ricardopereira](https://github.com/ricardopereira))
- HTTP Paginated Response [\#783](https://github.com/ably/ably-ios/pull/783) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSC7b test [\#782](https://github.com/ably/ably-ios/pull/782) ([funkyboy](https://github.com/funkyboy))
- RSC19a [\#754](https://github.com/ably/ably-ios/pull/754) ([ricardopereira](https://github.com/ricardopereira))

## [1.1.1](https://github.com/ably/ably-ios/tree/1.1.1) (2018-09-29)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.1.0...1.1.1)

**Fixed bugs:**

- Update SocketRocket dependency [\#804](https://github.com/ably/ably-ios/issues/804)

## [1.1.0](https://github.com/ably/ably-ios/tree/1.1.0) (2018-08-10)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.14...1.1.0)

**Implemented enhancements:**

- Upgrade to Xcode 9.4 [\#721](https://github.com/ably/ably-ios/issues/721)
- Update Swift to version 4.1 [\#716](https://github.com/ably/ably-ios/issues/716)
- Update protocol version to 1.1 [\#777](https://github.com/ably/ably-ios/pull/777)
- Update push API and push device authentication [\#761](https://github.com/ably/ably-ios/pull/761) ([funkyboy](https://github.com/funkyboy))
- Add max message size [\#759](https://github.com/ably/ably-ios/pull/759) ([funkyboy](https://github.com/funkyboy))

**Merged pull requests:**

- Update Cocoapods version [\#755](https://github.com/ably/ably-ios/pull/755) ([funkyboy](https://github.com/funkyboy))
- Fix some JWT tests [\#753](https://github.com/ably/ably-ios/pull/753) ([funkyboy](https://github.com/funkyboy))
- Add rtn15h2 [\#752](https://github.com/ably/ably-ios/pull/752) ([funkyboy](https://github.com/funkyboy))
- Fix flaky presence tests [\#751](https://github.com/ably/ably-ios/pull/751) ([funkyboy](https://github.com/funkyboy))
- Add rsa4e [\#750](https://github.com/ably/ably-ios/pull/750) ([funkyboy](https://github.com/funkyboy))
- Add rsa4d [\#748](https://github.com/ably/ably-ios/pull/748) ([funkyboy](https://github.com/funkyboy))
- Add tp3a test [\#747](https://github.com/ably/ably-ios/pull/747) ([funkyboy](https://github.com/funkyboy))
- Add test for RTE6a [\#746](https://github.com/ably/ably-ios/pull/746) ([funkyboy](https://github.com/funkyboy))
- Add test for TM2a [\#744](https://github.com/ably/ably-ios/pull/744) ([funkyboy](https://github.com/funkyboy))
- Set the Accept http header to the mime type of the selected encoder [\#743](https://github.com/ably/ably-ios/pull/743) ([funkyboy](https://github.com/funkyboy))
- Add cd2c [\#742](https://github.com/ably/ably-ios/pull/742) ([funkyboy](https://github.com/funkyboy))
- Add ABLY\_ENV support [\#740](https://github.com/ably/ably-ios/pull/740) ([funkyboy](https://github.com/funkyboy))
- Update ref to ably-common [\#739](https://github.com/ably/ably-ios/pull/739) ([funkyboy](https://github.com/funkyboy))
- Build Carthage dependencies only for iOS [\#738](https://github.com/ably/ably-ios/pull/738) ([funkyboy](https://github.com/funkyboy))
- Push missing tests [\#722](https://github.com/ably/ably-ios/pull/722) ([ricardopereira](https://github.com/ricardopereira))
- Push Activation State Machine missing tests [\#720](https://github.com/ably/ably-ios/pull/720) ([ricardopereira](https://github.com/ricardopereira))
- Push Channels tests [\#708](https://github.com/ably/ably-ios/pull/708) ([ricardopereira](https://github.com/ricardopereira))

## [1.0.14](https://github.com/ably/ably-ios/tree/1.0.14) (2018-06-18)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.13...1.0.14)

**Implemented enhancements:**

- Implement RTN15a [\#729](https://github.com/ably/ably-ios/issues/729)
- Improve RTN15G tests [\#725](https://github.com/ably/ably-ios/issues/725)
- Add test for JWT token [\#713](https://github.com/ably/ably-ios/issues/713)
- Implement connection state freshness check [\#645](https://github.com/ably/ably-ios/issues/645)

**Merged pull requests:**

- Fix race condition in preparing tests for push [\#733](https://github.com/ably/ably-ios/pull/733) ([funkyboy](https://github.com/funkyboy))
- Improve RTN15G tests [\#726](https://github.com/ably/ably-ios/pull/726) ([funkyboy](https://github.com/funkyboy))
- Add jwt tests [\#714](https://github.com/ably/ably-ios/pull/714) ([funkyboy](https://github.com/funkyboy))
- Add issue template [\#711](https://github.com/ably/ably-ios/pull/711) ([funkyboy](https://github.com/funkyboy))

## [1.0.13](https://github.com/ably/ably-ios/tree/1.0.13) (2018-05-14)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.12...1.0.13)

**Implemented enhancements:**

- Run CI on develop after a branch is merged [\#699](https://github.com/ably/ably-ios/issues/699)
- Investigate the performance of the iOS SDK vs the JS one [\#695](https://github.com/ably/ably-ios/issues/695)

**Closed issues:**

- realtime.ably.io is blocked in Russia [\#718](https://github.com/ably/ably-ios/issues/718)
- Channel history problem [\#717](https://github.com/ably/ably-ios/issues/717)
- Use of NSURLConnection [\#712](https://github.com/ably/ably-ios/issues/712)

**Merged pull requests:**

- Enforce new connection when last activity \> than \(idle interval + TTL\) [\#719](https://github.com/ably/ably-ios/pull/719) ([funkyboy](https://github.com/funkyboy))
- Add test for sequence of received messages [\#706](https://github.com/ably/ably-ios/pull/706) ([funkyboy](https://github.com/funkyboy))
- Add build of develop branch on Travis [\#705](https://github.com/ably/ably-ios/pull/705) ([funkyboy](https://github.com/funkyboy))
- Update contributing instructions [\#704](https://github.com/ably/ably-ios/pull/704) ([funkyboy](https://github.com/funkyboy))

## [1.0.12](https://github.com/ably/ably-ios/tree/1.0.12) (2018-03-16)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.11...1.0.12)

**Implemented enhancements:**

- Address warnings in KSCrash fork [\#680](https://github.com/ably/ably-ios/issues/680)

**Fixed bugs:**

- App Store publication issues when using Carthage [\#698](https://github.com/ably/ably-ios/issues/698)
- High Memory usage with my trackee channels [\#691](https://github.com/ably/ably-ios/issues/691)
- UI stuck at unsubscribe or calling subscribe when connection disconnected  [\#673](https://github.com/ably/ably-ios/issues/673)

**Closed issues:**

- Remove authorise  [\#677](https://github.com/ably/ably-ios/issues/677)
- Run Travis tests on iOS 9, 10 and 11 [\#675](https://github.com/ably/ably-ios/issues/675)
- Full test coverage of push functionality before GA release [\#632](https://github.com/ably/ably-ios/issues/632)
- Memory leak when publishing via realtime [\#625](https://github.com/ably/ably-ios/issues/625)

**Merged pull requests:**

- Fix memory consumption bug [\#702](https://github.com/ably/ably-ios/pull/702) ([funkyboy](https://github.com/funkyboy))
- Remove copy frameworks phase from the Xcode project [\#700](https://github.com/ably/ably-ios/pull/700) ([funkyboy](https://github.com/funkyboy))
- Add supported platform to README [\#693](https://github.com/ably/ably-ios/pull/693) ([funkyboy](https://github.com/funkyboy))
- Address KSCrash warnings [\#686](https://github.com/ably/ably-ios/pull/686) ([funkyboy](https://github.com/funkyboy))
- Pull specific version of SocketRocket [\#684](https://github.com/ably/ably-ios/pull/684) ([funkyboy](https://github.com/funkyboy))
- Remove deprecated authorise [\#679](https://github.com/ably/ably-ios/pull/679) ([funkyboy](https://github.com/funkyboy))
- Update release instructions [\#678](https://github.com/ably/ably-ios/pull/678) ([funkyboy](https://github.com/funkyboy))
- Push ActivationStateMachine tests [\#662](https://github.com/ably/ably-ios/pull/662) ([ricardopereira](https://github.com/ricardopereira))
- Push notifications [\#582](https://github.com/ably/ably-ios/pull/582) ([ricardopereira](https://github.com/ricardopereira))

## [1.0.11](https://github.com/ably/ably-ios/tree/1.0.11) (2018-01-31)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.10...1.0.11)

**Fixed bugs:**

- Uncaught Exception: '-\[\_\_NSCFURLSessionConnection performDefaultHandlingForAuthenticationChallenge:\]: unrecognized selector [\#674](https://github.com/ably/ably-ios/issues/674)

**Closed issues:**

- Update tests to Swift 4 [\#668](https://github.com/ably/ably-ios/issues/668)
- Push activation fails if already registered [\#661](https://github.com/ably/ably-ios/issues/661)
- Log from ably-ios client in an inconsistent state [\#659](https://github.com/ably/ably-ios/issues/659)
- ARTMessage.data is not converting into Dictionary [\#643](https://github.com/ably/ably-ios/issues/643)

**Merged pull requests:**

- Fix: check if `NSCFURLSessionConnection` responds to the `performDefaultHandlingForAuthenticationChallenge` selector [\#676](https://github.com/ably/ably-ios/pull/676) ([ricardopereira](https://github.com/ricardopereira))
- Swift 4: upgrade settings and dependencies [\#671](https://github.com/ably/ably-ios/pull/671) ([funkyboy](https://github.com/funkyboy))
- Fix format of section [\#666](https://github.com/ably/ably-ios/pull/666) ([funkyboy](https://github.com/funkyboy))

## [1.0.10](https://github.com/ably/ably-ios/tree/1.0.10) (2017-12-22)
[Full Changelog](https://github.com/ably/ably-ios/compare/v1.1.0-beta.push.1...1.0.10)

**Implemented enhancements:**

- Implement RTN23a idle timeout [\#638](https://github.com/ably/ably-ios/issues/638)
- Document thread-safety requirements in current version [\#601](https://github.com/ably/ably-ios/issues/601)
- Crash strategy [\#596](https://github.com/ably/ably-ios/issues/596)
- ART\* should match IDL definition [\#557](https://github.com/ably/ably-ios/issues/557)
- PagiantedResult isLast and hasNext are methods, not attributes [\#534](https://github.com/ably/ably-ios/issues/534)
- Auth: buffer of 15s for token expiry not implemented [\#115](https://github.com/ably/ably-ios/issues/115)

**Fixed bugs:**

- Presence map is using clientId as its key, rather than memberKey [\#641](https://github.com/ably/ably-ios/issues/641)
- Exception thrown when invoking \[\_channel unsubscribe\] [\#640](https://github.com/ably/ably-ios/issues/640)
- Presence map is accessible. [\#631](https://github.com/ably/ably-ios/issues/631)
- Pod installation issue: KSCrashAblyFork not found [\#615](https://github.com/ably/ably-ios/issues/615)
- Reported crash when an ATTACH is responded to with a DETACHED after a while [\#614](https://github.com/ably/ably-ios/issues/614)
- ARTPush didRegisterForRemoteNotificationsWithDeviceToken error [\#611](https://github.com/ably/ably-ios/issues/611)
- Crash in ARTOSReachability [\#593](https://github.com/ably/ably-ios/issues/593)
- Presence message timestamp interpretation is wrong [\#580](https://github.com/ably/ably-ios/issues/580)
- Library crash bug reports [\#553](https://github.com/ably/ably-ios/issues/553)
- Realtime: queued messages not handled like it is supposed to be [\#108](https://github.com/ably/ably-ios/issues/108)

**Closed issues:**

- Presence enter error coming [\#664](https://github.com/ably/ably-ios/issues/664)
- Rarely no incoming messages and no errors [\#657](https://github.com/ably/ably-ios/issues/657)
- Ably ios client closes connection 'WS:0x6000000befc0 websocket did disconnect \(code 1000\) \(null\)' [\#655](https://github.com/ably/ably-ios/issues/655)
- Deadlock in \[rest device\] when called from activation state machine [\#654](https://github.com/ably/ably-ios/issues/654)
- Not getting message when app is in Background [\#653](https://github.com/ably/ably-ios/issues/653)
- Clean CI build [\#652](https://github.com/ably/ably-ios/issues/652)
- How to deal with error "attempted to subscribe while channel is in Failed state" [\#650](https://github.com/ably/ably-ios/issues/650)
- Occasionally getting "Attached timed out" when using \[subscribeWithAttachCallback\] [\#649](https://github.com/ably/ably-ios/issues/649)
- Carthage Install Error [\#637](https://github.com/ably/ably-ios/issues/637)
- Crash in \[ARTRealtime transitionSideEffects:\] \(508\) [\#624](https://github.com/ably/ably-ios/issues/624)
- List of tests that are intermitently failing [\#283](https://github.com/ably/ably-ios/issues/283)
- RestClientStats tests are failing inconsistently. [\#142](https://github.com/ably/ably-ios/issues/142)
- Realtime: check test coverage for Queued Messages [\#109](https://github.com/ably/ably-ios/issues/109)
- Realtime: timeouts implementations are outdated [\#41](https://github.com/ably/ably-ios/issues/41)

**Merged pull requests:**

- Clean test suite [\#665](https://github.com/ably/ably-ios/pull/665) ([ricardopereira](https://github.com/ricardopereira))
- Push: fix deadlock in rest.device [\#663](https://github.com/ably/ably-ios/pull/663) ([ricardopereira](https://github.com/ricardopereira))
- RTN23 [\#660](https://github.com/ably/ably-ios/pull/660) ([ricardopereira](https://github.com/ricardopereira))
- Improve info about Carthage and contribution setup [\#658](https://github.com/ably/ably-ios/pull/658) ([ricardopereira](https://github.com/ricardopereira))
- Move to DISCONNECTED on unexpected WebSocket close. [\#656](https://github.com/ably/ably-ios/pull/656) ([tcard](https://github.com/tcard))
- Fix: when an ATTACH request is responded with a DETACHED [\#651](https://github.com/ably/ably-ios/pull/651) ([ricardopereira](https://github.com/ricardopereira))
- Fix: ambiguous reference to member 'dataTask\(with:completionHandler:\)' [\#648](https://github.com/ably/ably-ios/pull/648) ([ricardopereira](https://github.com/ricardopereira))
- Fix: presence map key and get with query \(clientId and connectionId\) [\#647](https://github.com/ably/ably-ios/pull/647) ([ricardopereira](https://github.com/ricardopereira))
- CocoaPod: add `private\_header\_files` prop [\#646](https://github.com/ably/ably-ios/pull/646) ([ricardopereira](https://github.com/ricardopereira))
- Fix \#640 [\#644](https://github.com/ably/ably-ios/pull/644) ([ricardopereira](https://github.com/ricardopereira))
- Push Admin tests [\#642](https://github.com/ably/ably-ios/pull/642) ([ricardopereira](https://github.com/ricardopereira))
- Carthage support [\#639](https://github.com/ably/ably-ios/pull/639) ([ricardopereira](https://github.com/ricardopereira))
## [1.0.9](https://github.com/ably/ably-ios/tree/1.0.9) (2017-09-15)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.8...1.0.9)

**Implemented enhancements:**

- Objective-C tests review [\#627](https://github.com/ably/ably-ios/issues/627)
- Spike: Review what's needed to use GCD to make the lib thread-safe [\#602](https://github.com/ably/ably-ios/issues/602)

**Closed issues:**

- Lib throws an exception if you try to do some actions when disconnected [\#635](https://github.com/ably/ably-ios/issues/635)
- Presence.enter on appWillEnterForeground, leave on appDidEnterBackground issues. [\#634](https://github.com/ably/ably-ios/issues/634)
- Push.activate callback not being called [\#633](https://github.com/ably/ably-ios/issues/633)
- RTP11d \(Presence.get when SUSPENDED\) not implemented; throws on DISCONNECTED [\#630](https://github.com/ably/ably-ios/issues/630)
- ARTPushActivationState Crash when call ably.push.activate [\#628](https://github.com/ably/ably-ios/issues/628)
- ACK: receiving a serial greater than expected [\#604](https://github.com/ably/ably-ios/issues/604)

**Merged pull requests:**

- Implement RTP11d. [\#636](https://github.com/ably/ably-ios/pull/636) ([tcard](https://github.com/tcard))
- Port legacy tests to Swift [\#629](https://github.com/ably/ably-ios/pull/629) ([ricardopereira](https://github.com/ricardopereira))

## [1.0.8](https://github.com/ably/ably-ios/tree/1.0.8) (2017-08-07)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.7...1.0.8)

**Closed issues:**

- 1.0 auth flow doesn't work? [\#622](https://github.com/ably/ably-ios/issues/622)

**Merged pull requests:**

- Reuse connection when receiving an AUTH. [\#623](https://github.com/ably/ably-ios/pull/623) ([tcard](https://github.com/tcard))
- \[WIP\] Make the library thread-safe. [\#620](https://github.com/ably/ably-ios/pull/620) ([tcard](https://github.com/tcard))

## [1.0.7](https://github.com/ably/ably-ios/tree/1.0.7) (2017-07-24)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.6...1.0.7)

**Fixed bugs:**

- TTL is being populated as a default for token requests in tokenRequestToDictionary method [\#618](https://github.com/ably/ably-ios/issues/618)

**Closed issues:**

- channel doesn't have 'subscribe' interface anymore? [\#621](https://github.com/ably/ably-ios/issues/621)
- Connection resume failure detaches all channels [\#612](https://github.com/ably/ably-ios/issues/612)
- 0.9 spec: Extras field [\#552](https://github.com/ably/ably-ios/issues/552)

**Merged pull requests:**

- Default token TTL to nil, not 60\*60. [\#619](https://github.com/ably/ably-ios/pull/619) ([tcard](https://github.com/tcard))
- Add extras field to Message. [\#617](https://github.com/ably/ably-ios/pull/617) ([tcard](https://github.com/tcard))

## [1.0.6](https://github.com/ably/ably-ios/tree/1.0.6) (2017-06-30)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.15...1.0.6)

**Merged pull requests:**

- Fix RTN15c3 [\#616](https://github.com/ably/ably-ios/pull/616) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.15](https://github.com/ably/ably-ios/tree/0.8.15) (2017-06-15)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.5...0.8.15)

## [1.0.5](https://github.com/ably/ably-ios/tree/1.0.5) (2017-06-15)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.14...1.0.5)

**Fixed bugs:**

- ably-ios ws spec breach: closing websockets with reserved close codes [\#605](https://github.com/ably/ably-ios/issues/605)
- Push: uncaught exception [\#594](https://github.com/ably/ably-ios/issues/594)

**Closed issues:**

- Use of unresolved identifier 'ARTPush' [\#595](https://github.com/ably/ably-ios/issues/595)

**Merged pull requests:**

- Convert to Swift 3. [\#613](https://github.com/ably/ably-ios/pull/613) ([tcard](https://github.com/tcard))
- Test suite [\#609](https://github.com/ably/ably-ios/pull/609) ([ricardopereira](https://github.com/ricardopereira))
- WebSocket: remove ARTWsAbnormalClose \(1006\) [\#606](https://github.com/ably/ably-ios/pull/606) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.14](https://github.com/ably/ably-ios/tree/0.8.14) (2017-05-15)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.4...0.8.14)

## [1.0.4](https://github.com/ably/ably-ios/tree/1.0.4) (2017-05-15)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.13...1.0.4)

**Merged pull requests:**

- Sentry. [\#603](https://github.com/ably/ably-ios/pull/603) ([tcard](https://github.com/tcard))
- WIP: Report crashes to Sentry. [\#599](https://github.com/ably/ably-ios/pull/599) ([tcard](https://github.com/tcard))
- Crashes [\#598](https://github.com/ably/ably-ios/pull/598) ([ricardopereira](https://github.com/ricardopereira))
- Log history [\#597](https://github.com/ably/ably-ios/pull/597) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.13](https://github.com/ably/ably-ios/tree/0.8.13) (2017-04-19)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.3...0.8.13)

## [1.0.3](https://github.com/ably/ably-ios/tree/1.0.3) (2017-04-19)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.2...1.0.3)

**Fixed bugs:**

- JSON encoding exception - handle encoding failures [\#591](https://github.com/ably/ably-ios/issues/591)

## [1.0.2](https://github.com/ably/ably-ios/tree/1.0.2) (2017-04-13)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.12...1.0.2)

## [0.8.12](https://github.com/ably/ably-ios/tree/0.8.12) (2017-04-13)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.1...0.8.12)

**Closed issues:**

- Crash in ARTJsonLikeEncoder [\#589](https://github.com/ably/ably-ios/issues/589)
- Release 1.0.0 [\#585](https://github.com/ably/ably-ios/issues/585)

**Merged pull requests:**

- Encoder: handle invalid types gracefully [\#592](https://github.com/ably/ably-ios/pull/592) ([ricardopereira](https://github.com/ricardopereira))

## [1.0.1](https://github.com/ably/ably-ios/tree/1.0.1) (2017-03-31)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.11...1.0.1)

## [0.8.11](https://github.com/ably/ably-ios/tree/0.8.11) (2017-03-31)
[Full Changelog](https://github.com/ably/ably-ios/compare/1.0.0...0.8.11)

**Fixed bugs:**

- Should Emphasize That ARTRealtime Needs To Be Created On Main Queue [\#577](https://github.com/ably/ably-ios/issues/577)
- Should not use the global listener for internal purpose [\#555](https://github.com/ably/ably-ios/issues/555)

**Merged pull requests:**

- Fix: should decode a protocol message that has an error without a message [\#590](https://github.com/ably/ably-ios/pull/590) ([ricardopereira](https://github.com/ricardopereira))

## [1.0.0](https://github.com/ably/ably-ios/tree/1.0.0) (2017-03-23)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.9.0...1.0.0)

**Implemented enhancements:**

- Fix HttpRequest & HttpRetry timeouts [\#583](https://github.com/ably/ably-ios/issues/583)

**Merged pull requests:**

- 0.9 master [\#588](https://github.com/ably/ably-ios/pull/588) ([ricardopereira](https://github.com/ricardopereira))

## [0.9.0](https://github.com/ably/ably-ios/tree/0.9.0) (2017-03-23)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.10...0.9.0)

**Closed issues:**

- Cannot install via Cocoapods with Xcode 7.3.1 [\#587](https://github.com/ably/ably-ios/issues/587)

**Merged pull requests:**

- Thread safety [\#586](https://github.com/ably/ably-ios/pull/586) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.10](https://github.com/ably/ably-ios/tree/0.8.10) (2017-03-11)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.9...0.8.10)

**Implemented enhancements:**

- Check 1.0 docs for accuracy against 0.9 changes [\#581](https://github.com/ably/ably-ios/issues/581)
- 0.9 presence spec amendments [\#565](https://github.com/ably/ably-ios/issues/565)
- ARTRealtimeChannel\* to ARTChannelState\* [\#556](https://github.com/ably/ably-ios/issues/556)
- Feedback from customer re private methods [\#554](https://github.com/ably/ably-ios/issues/554)

**Closed issues:**

- 0.9 spec: UPDATE event, replacing ERROR [\#551](https://github.com/ably/ably-ios/issues/551)
- Pending tests [\#541](https://github.com/ably/ably-ios/issues/541)
- AblyRealtime module renamed to Ably [\#510](https://github.com/ably/ably-ios/issues/510)
- Test Suite issues [\#469](https://github.com/ably/ably-ios/issues/469)

**Merged pull requests:**

- 0.8: Sandbox changes [\#584](https://github.com/ably/ably-ios/pull/584) ([ricardopereira](https://github.com/ricardopereira))
- Fix: Realtime transport should fire events on a serial queue [\#578](https://github.com/ably/ably-ios/pull/578) ([ricardopereira](https://github.com/ricardopereira))
- Update RSA10g for 0.9 [\#575](https://github.com/ably/ably-ios/pull/575) ([ricardopereira](https://github.com/ricardopereira))
- Update RSA9h for 0.9 [\#574](https://github.com/ably/ably-ios/pull/574) ([ricardopereira](https://github.com/ricardopereira))
- Update RSA8e for 0.9 [\#573](https://github.com/ably/ably-ios/pull/573) ([ricardopereira](https://github.com/ricardopereira))
- Update RTP8d for 0.9 [\#572](https://github.com/ably/ably-ios/pull/572) ([ricardopereira](https://github.com/ricardopereira))
- RTP17 [\#571](https://github.com/ably/ably-ios/pull/571) ([ricardopereira](https://github.com/ricardopereira))
- Update RTP5 for 0.9 [\#570](https://github.com/ably/ably-ios/pull/570) ([ricardopereira](https://github.com/ricardopereira))
- Swift performance: speed up code completion [\#569](https://github.com/ably/ably-ios/pull/569) ([ricardopereira](https://github.com/ricardopereira))
- RTP19 [\#568](https://github.com/ably/ably-ios/pull/568) ([ricardopereira](https://github.com/ricardopereira))
- RTP18 [\#567](https://github.com/ably/ably-ios/pull/567) ([ricardopereira](https://github.com/ricardopereira))
- Update RTP3 for 0.9 [\#566](https://github.com/ably/ably-ios/pull/566) ([ricardopereira](https://github.com/ricardopereira))
- Update RTP2 for 0.9 [\#563](https://github.com/ably/ably-ios/pull/563) ([ricardopereira](https://github.com/ricardopereira))
- TR4i [\#562](https://github.com/ably/ably-ios/pull/562) ([ricardopereira](https://github.com/ricardopereira))
- TH5 [\#561](https://github.com/ably/ably-ios/pull/561) ([ricardopereira](https://github.com/ricardopereira))
- Update RTN4 for 0.9 [\#560](https://github.com/ably/ably-ios/pull/560) ([ricardopereira](https://github.com/ricardopereira))
- UPDATE event [\#559](https://github.com/ably/ably-ios/pull/559) ([ricardopereira](https://github.com/ricardopereira))
- Xcode 8.2 \(Swift 2.3\) [\#558](https://github.com/ably/ably-ios/pull/558) ([ricardopereira](https://github.com/ricardopereira))
- Update RTL14 for 0.9 [\#550](https://github.com/ably/ably-ios/pull/550) ([ricardopereira](https://github.com/ricardopereira))
- Update RTL13 for 0.9 [\#549](https://github.com/ably/ably-ios/pull/549) ([ricardopereira](https://github.com/ricardopereira))
- Update RTL6c for 0.9 [\#547](https://github.com/ably/ably-ios/pull/547) ([ricardopereira](https://github.com/ricardopereira))
- Update RTL5 for 0.9 [\#546](https://github.com/ably/ably-ios/pull/546) ([ricardopereira](https://github.com/ricardopereira))
- Update RTL4 for 0.9 [\#545](https://github.com/ably/ably-ios/pull/545) ([ricardopereira](https://github.com/ricardopereira))
- Update RTL3 for 0.9 [\#544](https://github.com/ably/ably-ios/pull/544) ([ricardopereira](https://github.com/ricardopereira))
- Update RTL2 for 0.9  [\#543](https://github.com/ably/ably-ios/pull/543) ([ricardopereira](https://github.com/ricardopereira))
- Remove pending tests [\#542](https://github.com/ably/ably-ios/pull/542) ([ricardopereira](https://github.com/ricardopereira))
- RTN22 [\#537](https://github.com/ably/ably-ios/pull/537) ([ricardopereira](https://github.com/ricardopereira))
- RSA4c [\#519](https://github.com/ably/ably-ios/pull/519) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.9](https://github.com/ably/ably-ios/tree/0.8.9) (2016-12-06)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.8...0.8.9)

**Fixed bugs:**

- Connection resume does not fire channel detached [\#538](https://github.com/ably/ably-ios/issues/538)

**Closed issues:**

- 0.9 spec: fromJson [\#535](https://github.com/ably/ably-ios/issues/535)
- CFRunLoopPerformBlock never executes [\#531](https://github.com/ably/ably-ios/issues/531)
- Rename authorise API [\#496](https://github.com/ably/ably-ios/issues/496)

**Merged pull requests:**

- Fix: connection resume does not fire channel detached [\#539](https://github.com/ably/ably-ios/pull/539) ([ricardopereira](https://github.com/ricardopereira))
- RTC8 [\#526](https://github.com/ably/ably-ios/pull/526) ([ricardopereira](https://github.com/ricardopereira))
- RSA4b [\#518](https://github.com/ably/ably-ios/pull/518) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.8](https://github.com/ably/ably-ios/tree/0.8.8) (2016-11-22)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.7...0.8.8)

**Implemented enhancements:**

- Add reauth capability [\#452](https://github.com/ably/ably-ios/issues/452)

**Closed issues:**

- Ably requests include incomplete header values. [\#530](https://github.com/ably/ably-ios/issues/530)
- Token Request 'ttl' should be in milliseconds [\#529](https://github.com/ably/ably-ios/issues/529)
- Wrong message timestamp on 32-bit devices [\#525](https://github.com/ably/ably-ios/issues/525)
- Environment option is "production" [\#511](https://github.com/ably/ably-ios/issues/511)
- Sometimes test suite fails with: "Test target AblyTests encountered an error" [\#424](https://github.com/ably/ably-ios/issues/424)
- Issues noticed while reviewing tests marked as done [\#140](https://github.com/ably/ably-ios/issues/140)

**Merged pull requests:**

- Fix: check if authCallback is running on a background queue [\#536](https://github.com/ably/ably-ios/pull/536) ([ricardopereira](https://github.com/ricardopereira))
- TE6, TD7: Token{Request, Details}::fromJson [\#533](https://github.com/ably/ably-ios/pull/533) ([tcard](https://github.com/tcard))
- Don't read library version from bundle. [\#532](https://github.com/ably/ably-ios/pull/532) ([tcard](https://github.com/tcard))
- Fix timestamp decoding for 32-bit architectures. [\#528](https://github.com/ably/ably-ios/pull/528) ([tcard](https://github.com/tcard))
- Remove `AuthOptions.force` [\#527](https://github.com/ably/ably-ios/pull/527) ([ricardopereira](https://github.com/ricardopereira))
- RSA10l [\#524](https://github.com/ably/ably-ios/pull/524) ([ricardopereira](https://github.com/ricardopereira))
- Update RSA10g for 0.9 [\#523](https://github.com/ably/ably-ios/pull/523) ([ricardopereira](https://github.com/ricardopereira))
- Remove RSA10c and RSA10d [\#522](https://github.com/ably/ably-ios/pull/522) ([ricardopereira](https://github.com/ricardopereira))
- Update RSA10j for 0.9 [\#521](https://github.com/ably/ably-ios/pull/521) ([ricardopereira](https://github.com/ricardopereira))
- Update RSA10a for 0.9 [\#520](https://github.com/ably/ably-ios/pull/520) ([ricardopereira](https://github.com/ricardopereira))
- RSA4a [\#517](https://github.com/ably/ably-ios/pull/517) ([ricardopereira](https://github.com/ricardopereira))
- Update RSC15b for 0.9 [\#516](https://github.com/ably/ably-ios/pull/516) ([ricardopereira](https://github.com/ricardopereira))
- Update RSC15a for 0.9 [\#515](https://github.com/ably/ably-ios/pull/515) ([ricardopereira](https://github.com/ricardopereira))
- Update RSC15e for 0.9 [\#514](https://github.com/ably/ably-ios/pull/514) ([ricardopereira](https://github.com/ricardopereira))
- TO3k7 [\#513](https://github.com/ably/ably-ios/pull/513) ([ricardopereira](https://github.com/ricardopereira))
- Fix: when environment option is "production" [\#512](https://github.com/ably/ably-ios/pull/512) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.7](https://github.com/ably/ably-ios/tree/0.8.7) (2016-10-12)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.6...0.8.7)

**Merged pull requests:**

- Rename AblyRealtime to Ably [\#490](https://github.com/ably/ably-ios/pull/490) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.6](https://github.com/ably/ably-ios/tree/0.8.6) (2016-10-12)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.5...0.8.6)

**Fixed bugs:**

- Auth: `authUrl` can return a TokenRequest or the token itself [\#292](https://github.com/ably/ably-ios/issues/292)
- Realtime.connection: should store `connectionKey` when the client receives a CONNECTED message [\#118](https://github.com/ably/ably-ios/issues/118)
- Auth: request a token without an API key, authCallback or authUrl [\#117](https://github.com/ably/ably-ios/issues/117)
- Release POD [\#10](https://github.com/ably/ably-ios/issues/10)

**Closed issues:**

- Channel still has FAILED state after .attach\(\) call. [\#485](https://github.com/ably/ably-ios/issues/485)
- Add example for typical use of authCallback in README [\#461](https://github.com/ably/ably-ios/issues/461)
- Complete RSC11: missing host change feature [\#305](https://github.com/ably/ably-ios/issues/305)
- Update `podspec` when CocoaPods v1.0 is released in production [\#290](https://github.com/ably/ably-ios/issues/290)
- `ARTAuth` dependes on `ARTRest` and it shouldn't [\#27](https://github.com/ably/ably-ios/issues/27)

**Merged pull requests:**

- RSC15a [\#509](https://github.com/ably/ably-ios/pull/509) ([ricardopereira](https://github.com/ricardopereira))
- TK2d [\#508](https://github.com/ably/ably-ios/pull/508) ([ricardopereira](https://github.com/ricardopereira))
- Fix: should attach if the channel is in the FAILED state [\#507](https://github.com/ably/ably-ios/pull/507) ([ricardopereira](https://github.com/ricardopereira))
- Fix spec failures [\#506](https://github.com/ably/ably-ios/pull/506) ([ricardopereira](https://github.com/ricardopereira))
- Fix legacy tests: account blocked \(connection limits exceeded\) [\#505](https://github.com/ably/ably-ios/pull/505) ([ricardopereira](https://github.com/ricardopereira))
- RTN17с as a part of 0.9 [\#504](https://github.com/ably/ably-ios/pull/504) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RTN17b as a part of 0.9 [\#502](https://github.com/ably/ably-ios/pull/502) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RSC15a as a part of 0.9 [\#501](https://github.com/ably/ably-ios/pull/501) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RSC15b [\#499](https://github.com/ably/ably-ios/pull/499) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- Rename variable to fix compile time error. [\#498](https://github.com/ably/ably-ios/pull/498) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RSA10k [\#495](https://github.com/ably/ably-ios/pull/495) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RSA10g. [\#494](https://github.com/ably/ably-ios/pull/494) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RSA10d [\#493](https://github.com/ably/ably-ios/pull/493) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RSA10j [\#492](https://github.com/ably/ably-ios/pull/492) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RSA9h [\#491](https://github.com/ably/ably-ios/pull/491) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- Fix RSC11: ignore environment when host is customized [\#489](https://github.com/ably/ably-ios/pull/489) ([ricardopereira](https://github.com/ricardopereira))
- Internal listeners test [\#488](https://github.com/ably/ably-ios/pull/488) ([ricardopereira](https://github.com/ricardopereira))
- Rsa8e [\#487](https://github.com/ably/ably-ios/pull/487) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- Fixes 2 crashes that occurs during AblySpec tests execution. [\#486](https://github.com/ably/ably-ios/pull/486) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- RTN2f [\#484](https://github.com/ably/ably-ios/pull/484) ([ricardopereira](https://github.com/ricardopereira))
- RSC7a [\#483](https://github.com/ably/ably-ios/pull/483) ([ricardopereira](https://github.com/ricardopereira))
- Fix issue: should indicate an error if there is no way to renew the token [\#482](https://github.com/ably/ably-ios/pull/482) ([ricardopereira](https://github.com/ricardopereira))
- RTP15d [\#481](https://github.com/ably/ably-ios/pull/481) ([ricardopereira](https://github.com/ricardopereira))
- RTN4e [\#480](https://github.com/ably/ably-ios/pull/480) ([ricardopereira](https://github.com/ricardopereira))
- RTC2 [\#479](https://github.com/ably/ably-ios/pull/479) ([ricardopereira](https://github.com/ricardopereira))
- RTC1d [\#478](https://github.com/ably/ably-ios/pull/478) ([ricardopereira](https://github.com/ricardopereira))
- RSL5b [\#477](https://github.com/ably/ably-ios/pull/477) ([ricardopereira](https://github.com/ricardopereira))
- RSL2b [\#476](https://github.com/ably/ably-ios/pull/476) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSC10: check  the "otherwise" case [\#475](https://github.com/ably/ably-ios/pull/475) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSA8c: check authUrl content expectations [\#474](https://github.com/ably/ably-ios/pull/474) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSC11 [\#473](https://github.com/ably/ably-ios/pull/473) ([ricardopereira](https://github.com/ricardopereira))
- Swift snippet using the authCallback. [\#470](https://github.com/ably/ably-ios/pull/470) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- CI: update CocoaPod to v1.0.1 [\#467](https://github.com/ably/ably-ios/pull/467) ([ricardopereira](https://github.com/ricardopereira))
- RTN11b [\#419](https://github.com/ably/ably-ios/pull/419) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.5](https://github.com/ably/ably-ios/tree/0.8.5) (2016-08-26)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.4...0.8.5)

**Fixed bugs:**

- Incompatible clientId should cause a connection to fail or set the clientId on the socket [\#462](https://github.com/ably/ably-ios/issues/462)

**Closed issues:**

- 'Socket not connected' incorrectly leads to FAILED connection state rather than DISCONNECTED [\#471](https://github.com/ably/ably-ios/issues/471)
- SocketRocket/SRWebSocket.h file not found [\#463](https://github.com/ably/ably-ios/issues/463)

**Merged pull requests:**

- Move to DISCONNECTED when received "Socket is not connected" error. [\#472](https://github.com/ably/ably-ios/pull/472) ([tcard](https://github.com/tcard))
- Test suite: fix "account blocked \(connection limits exceeded\)" [\#468](https://github.com/ably/ably-ios/pull/468) ([ricardopereira](https://github.com/ricardopereira))
- Rtn2g [\#465](https://github.com/ably/ably-ios/pull/465) ([EvgenyKarkan](https://github.com/EvgenyKarkan))
- Rsc7b [\#464](https://github.com/ably/ably-ios/pull/464) ([EvgenyKarkan](https://github.com/EvgenyKarkan))

## [0.8.4](https://github.com/ably/ably-ios/tree/0.8.4) (2016-08-11)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.3...0.8.4)

**Merged pull requests:**

- Encode JSON message data as string. [\#459](https://github.com/ably/ably-ios/pull/459) ([tcard](https://github.com/tcard))
- Ensure graceful handling of DETACH and DISCONNECT. [\#455](https://github.com/ably/ably-ios/pull/455) ([tcard](https://github.com/tcard))

## [0.8.3](https://github.com/ably/ably-ios/tree/0.8.3) (2016-07-01)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.2...0.8.3)

**Closed issues:**

- Malformed message; no clientId in message or inferred from connection [\#451](https://github.com/ably/ably-ios/issues/451)
- Duplicated history [\#450](https://github.com/ably/ably-ios/issues/450)
- Have new CocoaPods version with SocketRocket? [\#449](https://github.com/ably/ably-ios/issues/449)
- Unable to connect using token auth [\#291](https://github.com/ably/ably-ios/issues/291)

**Merged pull requests:**

- Don't use auth when requesting tokens. [\#453](https://github.com/ably/ably-ios/pull/453) ([tcard](https://github.com/tcard))
- Add an example actual iOS app with tests. [\#448](https://github.com/ably/ably-ios/pull/448) ([tcard](https://github.com/tcard))

## [0.8.2](https://github.com/ably/ably-ios/tree/0.8.2) (2016-05-16)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.1...0.8.2)

**Implemented enhancements:**

- Update installation guide when Ably 0.8 podspec is live [\#294](https://github.com/ably/ably-ios/issues/294)
- Tests: better naming for MockTransport & MockHTTPExecutor [\#120](https://github.com/ably/ably-ios/issues/120)
- 0.8.x spec finalisation [\#107](https://github.com/ably/ably-ios/issues/107)

**Fixed bugs:**

- Presence: subscribe callback should provide an error [\#352](https://github.com/ably/ably-ios/issues/352)
- Presence: remaining query parameters not implemented [\#306](https://github.com/ably/ably-ios/issues/306)
- 0.8.x spec finalisation [\#107](https://github.com/ably/ably-ios/issues/107)

**Closed issues:**

- Add support for Swift 2.2 [\#345](https://github.com/ably/ably-ios/issues/345)

**Merged pull requests:**

- Add MessagePack support. [\#447](https://github.com/ably/ably-ios/pull/447) ([tcard](https://github.com/tcard))
- Fix RTN17a, RTN17c, RTN17e. [\#446](https://github.com/ably/ably-ios/pull/446) ([tcard](https://github.com/tcard))
- Fix race condition when calling ARTTestUtil.setupApp. [\#445](https://github.com/ably/ably-ios/pull/445) ([tcard](https://github.com/tcard))
- Several fixes in test suites. [\#443](https://github.com/ably/ably-ios/pull/443) ([tcard](https://github.com/tcard))
- RTN15h [\#442](https://github.com/ably/ably-ios/pull/442) ([ricardopereira](https://github.com/ricardopereira))
- Conform to spec changes at ably/docs\#112. [\#441](https://github.com/ably/ably-ios/pull/441) ([tcard](https://github.com/tcard))
- RTN20b [\#440](https://github.com/ably/ably-ios/pull/440) ([ricardopereira](https://github.com/ricardopereira))
- RTN20a [\#439](https://github.com/ably/ably-ios/pull/439) ([ricardopereira](https://github.com/ricardopereira))
- RTN15f [\#438](https://github.com/ably/ably-ios/pull/438) ([ricardopereira](https://github.com/ricardopereira))
- RTN13c [\#437](https://github.com/ably/ably-ios/pull/437) ([ricardopereira](https://github.com/ricardopereira))
- RTN13b [\#436](https://github.com/ably/ably-ios/pull/436) ([ricardopereira](https://github.com/ricardopereira))
- RTN13a [\#435](https://github.com/ably/ably-ios/pull/435) ([ricardopereira](https://github.com/ricardopereira))
- RSA7b4 [\#434](https://github.com/ably/ably-ios/pull/434) ([ricardopereira](https://github.com/ricardopereira))
- RSA7a4 [\#433](https://github.com/ably/ably-ios/pull/433) ([ricardopereira](https://github.com/ricardopereira))
- RSC8b [\#432](https://github.com/ably/ably-ios/pull/432) ([ricardopereira](https://github.com/ricardopereira))
- RTP15f [\#431](https://github.com/ably/ably-ios/pull/431) ([ricardopereira](https://github.com/ricardopereira))
- RTP15c [\#430](https://github.com/ably/ably-ios/pull/430) ([ricardopereira](https://github.com/ricardopereira))
- RTP14 [\#429](https://github.com/ably/ably-ios/pull/429) ([ricardopereira](https://github.com/ricardopereira))
- RTP13 [\#428](https://github.com/ably/ably-ios/pull/428) ([ricardopereira](https://github.com/ricardopereira))
- RTL6d [\#427](https://github.com/ably/ably-ios/pull/427) ([ricardopereira](https://github.com/ricardopereira))
- RTL6f [\#426](https://github.com/ably/ably-ios/pull/426) ([ricardopereira](https://github.com/ricardopereira))
- RTL6h [\#425](https://github.com/ably/ably-ios/pull/425) ([tcard](https://github.com/tcard))
- RTN14e [\#423](https://github.com/ably/ably-ios/pull/423) ([ricardopereira](https://github.com/ricardopereira))
- RTN14d [\#422](https://github.com/ably/ably-ios/pull/422) ([ricardopereira](https://github.com/ricardopereira))
- RTN14c [\#421](https://github.com/ably/ably-ios/pull/421) ([ricardopereira](https://github.com/ricardopereira))
- Test suites: reuse test app. [\#420](https://github.com/ably/ably-ios/pull/420) ([tcard](https://github.com/tcard))
- RSP5 [\#418](https://github.com/ably/ably-ios/pull/418) ([ricardopereira](https://github.com/ricardopereira))
- RSL1h [\#417](https://github.com/ably/ably-ios/pull/417) ([ricardopereira](https://github.com/ricardopereira))
- RSC13 [\#416](https://github.com/ably/ably-ios/pull/416) ([ricardopereira](https://github.com/ricardopereira))
- RSC12 [\#415](https://github.com/ably/ably-ios/pull/415) ([ricardopereira](https://github.com/ricardopereira))
- G4 [\#414](https://github.com/ably/ably-ios/pull/414) ([ricardopereira](https://github.com/ricardopereira))
- RTP10c [\#413](https://github.com/ably/ably-ios/pull/413) ([ricardopereira](https://github.com/ricardopereira))
- RTP9d [\#412](https://github.com/ably/ably-ios/pull/412) ([ricardopereira](https://github.com/ricardopereira))
- RTP8c [\#411](https://github.com/ably/ably-ios/pull/411) ([ricardopereira](https://github.com/ricardopereira))
- RTL12 [\#410](https://github.com/ably/ably-ios/pull/410) ([ricardopereira](https://github.com/ricardopereira))
- RTL6g4 [\#409](https://github.com/ably/ably-ios/pull/409) ([ricardopereira](https://github.com/ricardopereira))
- RTL6g3 [\#408](https://github.com/ably/ably-ios/pull/408) ([ricardopereira](https://github.com/ricardopereira))
- RTL6g2 [\#407](https://github.com/ably/ably-ios/pull/407) ([ricardopereira](https://github.com/ricardopereira))
- RTL6c [\#406](https://github.com/ably/ably-ios/pull/406) ([ricardopereira](https://github.com/ricardopereira))
- Legacy tests: Sandbox ClientOptions [\#405](https://github.com/ably/ably-ios/pull/405) ([ricardopereira](https://github.com/ricardopereira))
- ARTEventListener methods were using the `call` arg name instead of `callback` [\#404](https://github.com/ably/ably-ios/pull/404) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSA7b3 [\#403](https://github.com/ably/ably-ios/pull/403) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSA8f3 [\#402](https://github.com/ably/ably-ios/pull/402) ([ricardopereira](https://github.com/ricardopereira))
- RTN15c4 [\#401](https://github.com/ably/ably-ios/pull/401) ([ricardopereira](https://github.com/ricardopereira))
- RTN15c3 [\#400](https://github.com/ably/ably-ios/pull/400) ([ricardopereira](https://github.com/ricardopereira))
- RTN15c2 [\#399](https://github.com/ably/ably-ios/pull/399) ([ricardopereira](https://github.com/ricardopereira))
- RTN15c1 [\#398](https://github.com/ably/ably-ios/pull/398) ([ricardopereira](https://github.com/ricardopereira))
- RTN15b [\#396](https://github.com/ably/ably-ios/pull/396) ([ricardopereira](https://github.com/ricardopereira))
- RTN16e [\#395](https://github.com/ably/ably-ios/pull/395) ([ricardopereira](https://github.com/ricardopereira))
- RTN16d [\#394](https://github.com/ably/ably-ios/pull/394) ([ricardopereira](https://github.com/ricardopereira))
- RTN16c [\#393](https://github.com/ably/ably-ios/pull/393) ([ricardopereira](https://github.com/ricardopereira))
- RTN16b [\#392](https://github.com/ably/ably-ios/pull/392) ([ricardopereira](https://github.com/ricardopereira))
- RTN16a [\#391](https://github.com/ably/ably-ios/pull/391) ([ricardopereira](https://github.com/ricardopereira))
- RTN17e [\#390](https://github.com/ably/ably-ios/pull/390) ([ricardopereira](https://github.com/ricardopereira))
- RTN17d [\#389](https://github.com/ably/ably-ios/pull/389) ([ricardopereira](https://github.com/ricardopereira))
- RTN17c [\#388](https://github.com/ably/ably-ios/pull/388) ([ricardopereira](https://github.com/ricardopereira))
- RTN17a [\#387](https://github.com/ably/ably-ios/pull/387) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSC15b. [\#386](https://github.com/ably/ably-ios/pull/386) ([tcard](https://github.com/tcard))
- RTN17b [\#385](https://github.com/ably/ably-ios/pull/385) ([ricardopereira](https://github.com/ricardopereira))
- RSC15a [\#384](https://github.com/ably/ably-ios/pull/384) ([ricardopereira](https://github.com/ricardopereira))
- RSC15d [\#383](https://github.com/ably/ably-ios/pull/383) ([ricardopereira](https://github.com/ricardopereira))
- RSC15e [\#382](https://github.com/ably/ably-ios/pull/382) ([ricardopereira](https://github.com/ricardopereira))
- RSC15b [\#381](https://github.com/ably/ably-ios/pull/381) ([ricardopereira](https://github.com/ricardopereira))
- Test suite: renamed MockHTTPExecutor  to TestProxyHTTPExecutor [\#380](https://github.com/ably/ably-ios/pull/380) ([ricardopereira](https://github.com/ricardopereira))
- Fix Warnings: selectors migration [\#379](https://github.com/ably/ably-ios/pull/379) ([ricardopereira](https://github.com/ricardopereira))
- RSL1g4 [\#362](https://github.com/ably/ably-ios/pull/362) ([ricardopereira](https://github.com/ricardopereira))
- RSL1g3 [\#361](https://github.com/ably/ably-ios/pull/361) ([ricardopereira](https://github.com/ricardopereira))
- RSA8f1 [\#348](https://github.com/ably/ably-ios/pull/348) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.1](https://github.com/ably/ably-ios/tree/0.8.1) (2016-04-08)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.1-swift2.1...0.8.1)

**Merged pull requests:**

- Adapt to Swift 2.2 [\#378](https://github.com/ably/ably-ios/pull/378) ([tcard](https://github.com/tcard))

## [0.8.1-swift2.1](https://github.com/ably/ably-ios/tree/0.8.1-swift2.1) (2016-04-08)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8-swift2.1...0.8.1-swift2.1)

## [0.8-swift2.1](https://github.com/ably/ably-ios/tree/0.8-swift2.1) (2016-04-08)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.0...0.8-swift2.1)

**Merged pull requests:**

- Remove Ably.podspec. [\#377](https://github.com/ably/ably-ios/pull/377) ([tcard](https://github.com/tcard))
- Rearrange types relationships to avoid ambiguities. [\#376](https://github.com/ably/ably-ios/pull/376) ([tcard](https://github.com/tcard))
- RSP3a2 [\#365](https://github.com/ably/ably-ios/pull/365) ([ricardopereira](https://github.com/ricardopereira))
- RSA12b [\#355](https://github.com/ably/ably-ios/pull/355) ([ricardopereira](https://github.com/ricardopereira))
- RSA8f4 [\#351](https://github.com/ably/ably-ios/pull/351) ([ricardopereira](https://github.com/ricardopereira))
- RSA8f3 [\#350](https://github.com/ably/ably-ios/pull/350) ([ricardopereira](https://github.com/ricardopereira))
- RSA8f2 [\#349](https://github.com/ably/ably-ios/pull/349) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.0](https://github.com/ably/ably-ios/tree/0.8.0) (2016-04-06)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.0-beta.3...0.8.0)

**Implemented enhancements:**

- Core: `ARTErrorInfo` should be related with `NSError` [\#126](https://github.com/ably/ably-ios/issues/126)

**Closed issues:**

- Update README and docs examples to conform commit 897ce0f [\#304](https://github.com/ably/ably-ios/issues/304)
- RealtimePresence.get shouldn't wrap RestPresence.get. [\#271](https://github.com/ably/ably-ios/issues/271)

**Merged pull requests:**

- Release 0.8.0. [\#375](https://github.com/ably/ably-ios/pull/375) ([tcard](https://github.com/tcard))
- Fix RSP4b1 [\#374](https://github.com/ably/ably-ios/pull/374) ([ricardopereira](https://github.com/ricardopereira))
- Swift 2.2 [\#373](https://github.com/ably/ably-ios/pull/373) ([ricardopereira](https://github.com/ricardopereira))
- RTP8a, RTL7f: attach first to avoid race condition. [\#372](https://github.com/ably/ably-ios/pull/372) ([tcard](https://github.com/tcard))
- Fix pending tests. [\#371](https://github.com/ably/ably-ios/pull/371) ([tcard](https://github.com/tcard))
- RSP4b3 [\#370](https://github.com/ably/ably-ios/pull/370) ([ricardopereira](https://github.com/ricardopereira))
- RSP4b2 [\#369](https://github.com/ably/ably-ios/pull/369) ([ricardopereira](https://github.com/ricardopereira))
- RSP4b1 [\#368](https://github.com/ably/ably-ios/pull/368) ([ricardopereira](https://github.com/ricardopereira))
- RSP4a [\#367](https://github.com/ably/ably-ios/pull/367) ([ricardopereira](https://github.com/ricardopereira))
- RSP3a3 [\#366](https://github.com/ably/ably-ios/pull/366) ([ricardopereira](https://github.com/ricardopereira))
- RSP3a1 [\#364](https://github.com/ably/ably-ios/pull/364) ([ricardopereira](https://github.com/ricardopereira))
- RSL6b [\#363](https://github.com/ably/ably-ios/pull/363) ([ricardopereira](https://github.com/ricardopereira))
- RSL1g2 [\#360](https://github.com/ably/ably-ios/pull/360) ([ricardopereira](https://github.com/ricardopereira))
- RSL1g1 [\#359](https://github.com/ably/ably-ios/pull/359) ([ricardopereira](https://github.com/ricardopereira))
- RSL1f1 [\#358](https://github.com/ably/ably-ios/pull/358) ([ricardopereira](https://github.com/ricardopereira))
- RTN19 [\#357](https://github.com/ably/ably-ios/pull/357) ([ricardopereira](https://github.com/ricardopereira))
- RSA7b3 [\#356](https://github.com/ably/ably-ios/pull/356) ([ricardopereira](https://github.com/ricardopereira))
- RSA12a [\#354](https://github.com/ably/ably-ios/pull/354) ([ricardopereira](https://github.com/ricardopereira))
- RSA15c [\#353](https://github.com/ably/ably-ios/pull/353) ([ricardopereira](https://github.com/ricardopereira))
- RSA8d [\#347](https://github.com/ably/ably-ios/pull/347) ([ricardopereira](https://github.com/ricardopereira))
- RSA8c2 [\#346](https://github.com/ably/ably-ios/pull/346) ([ricardopereira](https://github.com/ricardopereira))
- RTN19b [\#344](https://github.com/ably/ably-ios/pull/344) ([ricardopereira](https://github.com/ricardopereira))
- RTN19a [\#343](https://github.com/ably/ably-ios/pull/343) ([ricardopereira](https://github.com/ricardopereira))
- RTP12c [\#342](https://github.com/ably/ably-ios/pull/342) ([ricardopereira](https://github.com/ricardopereira))
- RTP12b [\#341](https://github.com/ably/ably-ios/pull/341) ([ricardopereira](https://github.com/ricardopereira))
- RTP12a [\#340](https://github.com/ably/ably-ios/pull/340) ([ricardopereira](https://github.com/ricardopereira))
- RTP11c1 [\#339](https://github.com/ably/ably-ios/pull/339) ([ricardopereira](https://github.com/ricardopereira))
- RTP10e [\#338](https://github.com/ably/ably-ios/pull/338) ([ricardopereira](https://github.com/ricardopereira))
- RTP10b [\#337](https://github.com/ably/ably-ios/pull/337) ([ricardopereira](https://github.com/ricardopereira))
- RTP10a [\#336](https://github.com/ably/ably-ios/pull/336) ([ricardopereira](https://github.com/ricardopereira))
- RTP9e [\#335](https://github.com/ably/ably-ios/pull/335) ([ricardopereira](https://github.com/ricardopereira))
- RTP9c [\#334](https://github.com/ably/ably-ios/pull/334) ([ricardopereira](https://github.com/ricardopereira))
- RTP9b [\#333](https://github.com/ably/ably-ios/pull/333) ([ricardopereira](https://github.com/ricardopereira))
- RTP9a [\#332](https://github.com/ably/ably-ios/pull/332) ([ricardopereira](https://github.com/ricardopereira))
- RTP8i [\#331](https://github.com/ably/ably-ios/pull/331) ([ricardopereira](https://github.com/ricardopereira))
- RTP8h [\#330](https://github.com/ably/ably-ios/pull/330) ([ricardopereira](https://github.com/ricardopereira))
- RTP8g [\#329](https://github.com/ably/ably-ios/pull/329) ([ricardopereira](https://github.com/ricardopereira))
- RTP8f [\#328](https://github.com/ably/ably-ios/pull/328) ([ricardopereira](https://github.com/ricardopereira))
- RTP8e [\#327](https://github.com/ably/ably-ios/pull/327) ([ricardopereira](https://github.com/ricardopereira))
- RTP8d [\#326](https://github.com/ably/ably-ios/pull/326) ([ricardopereira](https://github.com/ricardopereira))
- RTP8b [\#325](https://github.com/ably/ably-ios/pull/325) ([ricardopereira](https://github.com/ricardopereira))
- RTP8a [\#324](https://github.com/ably/ably-ios/pull/324) ([ricardopereira](https://github.com/ricardopereira))
- RTP7b [\#323](https://github.com/ably/ably-ios/pull/323) ([ricardopereira](https://github.com/ricardopereira))
- RTP7a [\#322](https://github.com/ably/ably-ios/pull/322) ([ricardopereira](https://github.com/ricardopereira))
- RTP6c [\#321](https://github.com/ably/ably-ios/pull/321) ([ricardopereira](https://github.com/ricardopereira))
- RTP6b [\#320](https://github.com/ably/ably-ios/pull/320) ([ricardopereira](https://github.com/ricardopereira))
- RTP6a [\#319](https://github.com/ably/ably-ios/pull/319) ([ricardopereira](https://github.com/ricardopereira))
- RTP16c [\#318](https://github.com/ably/ably-ios/pull/318) ([ricardopereira](https://github.com/ricardopereira))
- RTP16b [\#317](https://github.com/ably/ably-ios/pull/317) ([ricardopereira](https://github.com/ricardopereira))
- RTP16a [\#316](https://github.com/ably/ably-ios/pull/316) ([ricardopereira](https://github.com/ricardopereira))
- RTP5b [\#315](https://github.com/ably/ably-ios/pull/315) ([ricardopereira](https://github.com/ricardopereira))
- RTP5a [\#314](https://github.com/ably/ably-ios/pull/314) ([ricardopereira](https://github.com/ricardopereira))
- RTP4 [\#313](https://github.com/ably/ably-ios/pull/313) ([ricardopereira](https://github.com/ricardopereira))
- RTP3 [\#312](https://github.com/ably/ably-ios/pull/312) ([ricardopereira](https://github.com/ricardopereira))
- RTP2 [\#311](https://github.com/ably/ably-ios/pull/311) ([ricardopereira](https://github.com/ricardopereira))
- README: Replace NSError with ARTErrorInfo [\#310](https://github.com/ably/ably-ios/pull/310) ([ricardopereira](https://github.com/ricardopereira))
- RTP11b [\#309](https://github.com/ably/ably-ios/pull/309) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.0-beta.3](https://github.com/ably/ably-ios/tree/0.8.0-beta.3) (2016-03-18)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.0-beta.2...0.8.0-beta.3)

**Merged pull requests:**

- RSP3a [\#308](https://github.com/ably/ably-ios/pull/308) ([ricardopereira](https://github.com/ricardopereira))
- AblyRealtime pod [\#307](https://github.com/ably/ably-ios/pull/307) ([ricardopereira](https://github.com/ricardopereira))
- Fix: expect timestamp with higher delta [\#301](https://github.com/ably/ably-ios/pull/301) ([ricardopereira](https://github.com/ricardopereira))
- Fix RealtimePresence.get [\#299](https://github.com/ably/ably-ios/pull/299) ([ricardopereira](https://github.com/ricardopereira))
- RTP11a [\#296](https://github.com/ably/ably-ios/pull/296) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.0-beta.2](https://github.com/ably/ably-ios/tree/0.8.0-beta.2) (2016-03-17)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.8.0-beta.1...0.8.0-beta.2)

**Implemented enhancements:**

- Review the known limitations  [\#106](https://github.com/ably/ably-ios/issues/106)
- Changelog + bump version [\#104](https://github.com/ably/ably-ios/issues/104)
- Spec links must link to this repo [\#102](https://github.com/ably/ably-ios/issues/102)

**Fixed bugs:**

- Spec links must link to this repo [\#102](https://github.com/ably/ably-ios/issues/102)
- Realtime: there is no dedicated object to manage connections [\#36](https://github.com/ably/ably-ios/issues/36)

**Closed issues:**

- Travis CI is stalling in some builds [\#143](https://github.com/ably/ably-ios/issues/143)
- Realtime: check test coverage for Connection State Transition [\#110](https://github.com/ably/ably-ios/issues/110)
- No visible @interface for 'ARTRealtime' declares the selector 'subscribeToStateChanges:' [\#20](https://github.com/ably/ably-ios/issues/20)

**Merged pull requests:**

- Test suite: avoid calling the `fulfill` after the wait context has ended [\#303](https://github.com/ably/ably-ios/pull/303) ([ricardopereira](https://github.com/ricardopereira))
- Enhance RTL7f: speed up [\#302](https://github.com/ably/ably-ios/pull/302) ([ricardopereira](https://github.com/ricardopereira))
- Legacy tests: speed up [\#300](https://github.com/ably/ably-ios/pull/300) ([ricardopereira](https://github.com/ricardopereira))
- Fix typo in ARTDataQuery.m [\#297](https://github.com/ably/ably-ios/pull/297) ([stannedelchev](https://github.com/stannedelchev))
- Fix RTL5b [\#295](https://github.com/ably/ably-ios/pull/295) ([ricardopereira](https://github.com/ricardopereira))
- Use Ably pod with descentralised source [\#293](https://github.com/ably/ably-ios/pull/293) ([ricardopereira](https://github.com/ricardopereira))
- Fix uncaught HTTP exception [\#289](https://github.com/ably/ably-ios/pull/289) ([ricardopereira](https://github.com/ricardopereira))
- RTP15e [\#288](https://github.com/ably/ably-ios/pull/288) ([ricardopereira](https://github.com/ricardopereira))
- Test suite: use log level "Info" [\#287](https://github.com/ably/ably-ios/pull/287) ([ricardopereira](https://github.com/ricardopereira))
- Fix RTL1 [\#286](https://github.com/ably/ably-ios/pull/286) ([ricardopereira](https://github.com/ricardopereira))
- Standardise on initialized [\#284](https://github.com/ably/ably-ios/pull/284) ([SimonWoolf](https://github.com/SimonWoolf))
- RTP1 [\#282](https://github.com/ably/ably-ios/pull/282) ([ricardopereira](https://github.com/ricardopereira))
- Renamed last cb: argument to callback: [\#281](https://github.com/ably/ably-ios/pull/281) ([ricardopereira](https://github.com/ricardopereira))
- Project: add Realtime Presence file to Spec [\#280](https://github.com/ably/ably-ios/pull/280) ([ricardopereira](https://github.com/ricardopereira))
- RTS3 [\#279](https://github.com/ably/ably-ios/pull/279) ([ricardopereira](https://github.com/ricardopereira))
- Remove pending from RestClientStats [\#278](https://github.com/ably/ably-ios/pull/278) ([ricardopereira](https://github.com/ricardopereira))

## [0.8.0-beta.1](https://github.com/ably/ably-ios/tree/0.8.0-beta.1) (2016-03-04)
[Full Changelog](https://github.com/ably/ably-ios/compare/0.7.0...0.8.0-beta.1)

**Implemented enhancements:**

- New Crypto spec [\#264](https://github.com/ably/ably-ios/issues/264)
- ARTPayload: class review [\#130](https://github.com/ably/ably-ios/issues/130)
- Channel: consistent `publish` methods between other platform clients [\#121](https://github.com/ably/ably-ios/issues/121)
- Stats: `decodeStats` should use \_nonnull\_ instances [\#113](https://github.com/ably/ably-ios/issues/113)
- Tests: use `defer` statement to close the connection [\#112](https://github.com/ably/ably-ios/issues/112)
- Readme examples updated + Swift support [\#105](https://github.com/ably/ably-ios/issues/105)
- Switch arity of auth methods [\#24](https://github.com/ably/ably-ios/issues/24)
- Spec validation [\#11](https://github.com/ably/ably-ios/issues/11)
- README must contain working examples in line with other client libraries [\#6](https://github.com/ably/ably-ios/issues/6)
- API changes Apr 2015 [\#4](https://github.com/ably/ably-ios/issues/4)

**Fixed bugs:**

- Subscribing without waiting for connection doesn't attach [\#218](https://github.com/ably/ably-ios/issues/218)
- Realtime: close connection doesn't wait for the confirmation \(CLOSED action\) [\#191](https://github.com/ably/ably-ios/issues/191)
- RealtimeChannel: attach is inconsistent with the API [\#189](https://github.com/ably/ably-ios/issues/189)
- RealtimeChannel: channel subscribe messages is inconsistent with the API [\#183](https://github.com/ably/ably-ios/issues/183)
- RealtimeChannel: channel state changes is inconsistent with the API [\#134](https://github.com/ably/ably-ios/issues/134)
- Realtime: connection state changes is inconsistent with the API [\#133](https://github.com/ably/ably-ios/issues/133)
- Realtime: implement ARTConnection & ARTConnectionDetails [\#132](https://github.com/ably/ably-ios/issues/132)
- AuthTokenParams should not contain a default timestamp [\#129](https://github.com/ably/ably-ios/issues/129)
- RealtimeChannel: duplicated `publish` method [\#127](https://github.com/ably/ably-ios/issues/127)
- Stats: Stats object properties are never nullable [\#116](https://github.com/ably/ably-ios/issues/116)
- Auth: store TokenParams for subsequent authorisations [\#114](https://github.com/ably/ably-ios/issues/114)
- Stats: `decodeStats` should use \\_nonnull\\_ instances [\#113](https://github.com/ably/ably-ios/issues/113)
- Priority: Test suite passing [\#103](https://github.com/ably/ably-ios/issues/103)
- Rest: message decoding [\#97](https://github.com/ably/ably-ios/issues/97)
- Switch arity of auth methods [\#24](https://github.com/ably/ably-ios/issues/24)
- API changes Apr 2015 [\#4](https://github.com/ably/ably-ios/issues/4)

**Closed issues:**

- Channel\#history: `query.untilAttach` feature [\#234](https://github.com/ably/ably-ios/issues/234)
- subscribe should optionally take an additional error callback [\#220](https://github.com/ably/ably-ios/issues/220)
- ARTDataDecoded: error decoding a NSDictionary or NSArray [\#195](https://github.com/ably/ably-ios/issues/195)
- Test ably-common/test-resources/crypto-data-\*.json. [\#181](https://github.com/ably/ably-ios/issues/181)
- ARTAuthTokenParams: `ttl` type is not consistent with spec [\#131](https://github.com/ably/ably-ios/issues/131)
- Realtime: add `dispose` method [\#111](https://github.com/ably/ably-ios/issues/111)
- Rest: message encoding [\#95](https://github.com/ably/ably-ios/issues/95)
- Realtime: missing `connectionDetails` property [\#88](https://github.com/ably/ably-ios/issues/88)
- Travis: iOS 9 simulator [\#79](https://github.com/ably/ably-ios/issues/79)
- Travis: Integrate XCTool or Fastlane [\#78](https://github.com/ably/ably-ios/issues/78)
- Tests: List of ObjC tests [\#48](https://github.com/ably/ably-ios/issues/48)
- `ARTRest` should request access token automatically [\#28](https://github.com/ably/ably-ios/issues/28)
- Unable to connect to Ably [\#22](https://github.com/ably/ably-ios/issues/22)
- Error: "Either a token, token param, or a keyName and secret are required to connect to Ably" [\#21](https://github.com/ably/ably-ios/issues/21)

**Merged pull requests:**

- Fix warnings [\#277](https://github.com/ably/ably-ios/pull/277) ([ricardopereira](https://github.com/ricardopereira))
- Travis enhancements [\#276](https://github.com/ably/ably-ios/pull/276) ([ricardopereira](https://github.com/ricardopereira))
- Remove block typedefs, use block syntax explicitly. [\#275](https://github.com/ably/ably-ios/pull/275) ([tcard](https://github.com/tcard))
- Rename all cb: to callback: [\#274](https://github.com/ably/ably-ios/pull/274) ([tcard](https://github.com/tcard))
- Use ErrorInfo instead of internal ARTStatus in ping callback. [\#273](https://github.com/ably/ably-ios/pull/273) ([tcard](https://github.com/tcard))
- Fix RTL7e [\#272](https://github.com/ably/ably-ios/pull/272) ([ricardopereira](https://github.com/ricardopereira))
- Travis: fix stalled build [\#270](https://github.com/ably/ably-ios/pull/270) ([ricardopereira](https://github.com/ricardopereira))
- Project rename: ably to Ably [\#269](https://github.com/ably/ably-ios/pull/269) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSN4: releaseChannel [\#268](https://github.com/ably/ably-ios/pull/268) ([ricardopereira](https://github.com/ricardopereira))
- Fix RSC1: initWithKey test [\#266](https://github.com/ably/ably-ios/pull/266) ([ricardopereira](https://github.com/ricardopereira))
- Xcode 7.2 \(use xcodebuild\) [\#265](https://github.com/ably/ably-ios/pull/265) ([ricardopereira](https://github.com/ricardopereira))
- Test RTL5\*. [\#262](https://github.com/ably/ably-ios/pull/262) ([tcard](https://github.com/tcard))
- Test RSA9h. [\#261](https://github.com/ably/ably-ios/pull/261) ([tcard](https://github.com/tcard))
- Fix RTN14b test. [\#260](https://github.com/ably/ably-ios/pull/260) ([tcard](https://github.com/tcard))
- Fix RTN10c test. [\#259](https://github.com/ably/ably-ios/pull/259) ([tcard](https://github.com/tcard))
- Fix RTL6g1 test. [\#258](https://github.com/ably/ably-ios/pull/258) ([tcard](https://github.com/tcard))
- Remove 'pending' from RTN12a, RTN12b. [\#257](https://github.com/ably/ably-ios/pull/257) ([tcard](https://github.com/tcard))
- Remove 'pending' from RSC2 test. [\#256](https://github.com/ably/ably-ios/pull/256) ([tcard](https://github.com/tcard))
- Fix RSC1: Rest constructor should accept a token. [\#255](https://github.com/ably/ably-ios/pull/255) ([tcard](https://github.com/tcard))
- Fix RTN18b: channels detach on suspended connection. [\#254](https://github.com/ably/ably-ios/pull/254) ([tcard](https://github.com/tcard))
- Fix RTL7d: error on decoding message. [\#253](https://github.com/ably/ably-ios/pull/253) ([tcard](https://github.com/tcard))
- Fix RTL7c: channel.subscribe fails when channel is FAILED. [\#252](https://github.com/ably/ably-ios/pull/252) ([tcard](https://github.com/tcard))
- RTN15e [\#251](https://github.com/ably/ably-ios/pull/251) ([ricardopereira](https://github.com/ricardopereira))
- RTN15g [\#250](https://github.com/ably/ably-ios/pull/250) ([ricardopereira](https://github.com/ricardopereira))
- RTN15d [\#249](https://github.com/ably/ably-ios/pull/249) ([ricardopereira](https://github.com/ricardopereira))
- Uniformize stats and history interfaces. [\#248](https://github.com/ably/ably-ios/pull/248) ([tcard](https://github.com/tcard))
- TokenParams.timestamp: use current at getter, not at constructor. [\#247](https://github.com/ably/ably-ios/pull/247) ([tcard](https://github.com/tcard))
- RTL10b: Implement untilAttach for RealtimeChannel.history. [\#246](https://github.com/ably/ably-ios/pull/246) ([tcard](https://github.com/tcard))
- Connection EventEmitter: use enum instead of NSNumber as event type. [\#245](https://github.com/ably/ably-ios/pull/245) ([tcard](https://github.com/tcard))
- RTN15a [\#244](https://github.com/ably/ably-ios/pull/244) ([ricardopereira](https://github.com/ricardopereira))
- Test suite: fix warning about duplicated class references [\#243](https://github.com/ably/ably-ios/pull/243) ([ricardopereira](https://github.com/ricardopereira))
- History request without a query shouldn't throw errors [\#242](https://github.com/ably/ably-ios/pull/242) ([ricardopereira](https://github.com/ricardopereira))
- RTL2c [\#241](https://github.com/ably/ably-ios/pull/241) ([ricardopereira](https://github.com/ricardopereira))
- RTL2b [\#240](https://github.com/ably/ably-ios/pull/240) ([ricardopereira](https://github.com/ricardopereira))
- RTL2a [\#239](https://github.com/ably/ably-ios/pull/239) ([ricardopereira](https://github.com/ricardopereira))
- Test suite enhancements [\#238](https://github.com/ably/ably-ios/pull/238) ([ricardopereira](https://github.com/ricardopereira))
- RTL10d [\#237](https://github.com/ably/ably-ios/pull/237) ([ricardopereira](https://github.com/ricardopereira))
- Force full channel release. [\#236](https://github.com/ably/ably-ios/pull/236) ([tcard](https://github.com/tcard))
- RTL10c [\#235](https://github.com/ably/ably-ios/pull/235) ([ricardopereira](https://github.com/ricardopereira))
- RTL10b [\#233](https://github.com/ably/ably-ios/pull/233) ([ricardopereira](https://github.com/ricardopereira))
- Fix attach callbacks, and add to RealtimeChannel.subscribe. [\#232](https://github.com/ably/ably-ios/pull/232) ([tcard](https://github.com/tcard))
- Adjust Crypto, CipherParams and ChannelOptions to spec. [\#231](https://github.com/ably/ably-ios/pull/231) ([tcard](https://github.com/tcard))
- Fix RTN10b. [\#230](https://github.com/ably/ably-ios/pull/230) ([tcard](https://github.com/tcard))
- RTL10a [\#229](https://github.com/ably/ably-ios/pull/229) ([ricardopereira](https://github.com/ricardopereira))
- Fix RTN7c: notify publish callbacks of broken connection. [\#228](https://github.com/ably/ably-ios/pull/228) ([tcard](https://github.com/tcard))
- Remove 'pending' from RTL6e1. [\#227](https://github.com/ably/ably-ios/pull/227) ([tcard](https://github.com/tcard))
- Fix RTL4f. [\#226](https://github.com/ably/ably-ios/pull/226) ([tcard](https://github.com/tcard))
- Fix RTL4a. [\#224](https://github.com/ably/ably-ios/pull/224) ([tcard](https://github.com/tcard))
- Fix RTL3b and RTL4b. [\#223](https://github.com/ably/ably-ios/pull/223) ([tcard](https://github.com/tcard))
- Remove 'pending' from RSN4 test. [\#222](https://github.com/ably/ably-ios/pull/222) ([tcard](https://github.com/tcard))
- Fix RTL3a. [\#221](https://github.com/ably/ably-ios/pull/221) ([tcard](https://github.com/tcard))
- RTL8 [\#219](https://github.com/ably/ably-ios/pull/219) ([ricardopereira](https://github.com/ricardopereira))
- Fix message encoding and encryption. [\#217](https://github.com/ably/ably-ios/pull/217) ([tcard](https://github.com/tcard))
- Swift Readme Examples: use Quick [\#216](https://github.com/ably/ably-ios/pull/216) ([ricardopereira](https://github.com/ricardopereira))
- Gitignore: test report [\#215](https://github.com/ably/ably-ios/pull/215) ([ricardopereira](https://github.com/ricardopereira))
- Carthage support [\#214](https://github.com/ably/ably-ios/pull/214) ([ricardopereira](https://github.com/ricardopereira))
- Pod support [\#213](https://github.com/ably/ably-ios/pull/213) ([ricardopereira](https://github.com/ricardopereira))
- RTL7f [\#212](https://github.com/ably/ably-ios/pull/212) ([ricardopereira](https://github.com/ricardopereira))
- RTL7e [\#211](https://github.com/ably/ably-ios/pull/211) ([ricardopereira](https://github.com/ricardopereira))
- Pods: Quick and Nimble update [\#210](https://github.com/ably/ably-ios/pull/210) ([ricardopereira](https://github.com/ricardopereira))
- RTL7d [\#209](https://github.com/ably/ably-ios/pull/209) ([ricardopereira](https://github.com/ricardopereira))
- RTL7c [\#208](https://github.com/ably/ably-ios/pull/208) ([ricardopereira](https://github.com/ricardopereira))
- RTL7b [\#207](https://github.com/ably/ably-ios/pull/207) ([ricardopereira](https://github.com/ricardopereira))
- RTL7a [\#206](https://github.com/ably/ably-ios/pull/206) ([ricardopereira](https://github.com/ricardopereira))
- RTL6g [\#205](https://github.com/ably/ably-ios/pull/205) ([ricardopereira](https://github.com/ricardopereira))
- General adjustment to API spec. [\#204](https://github.com/ably/ably-ios/pull/204) ([tcard](https://github.com/tcard))
- TG4: PaginatedResult.next calls back with nil if there's no next. [\#203](https://github.com/ably/ably-ios/pull/203) ([tcard](https://github.com/tcard))
- Minor changes to adjust to API spec. [\#202](https://github.com/ably/ably-ios/pull/202) ([tcard](https://github.com/tcard))
- Separate BaseMessage private parts. [\#201](https://github.com/ably/ably-ios/pull/201) ([tcard](https://github.com/tcard))
- Remove 'Auth' prefix from TokenDetails, TokenRequest, TokenParams. [\#200](https://github.com/ably/ably-ios/pull/200) ([tcard](https://github.com/tcard))
- Fix RTL4b: use client.channels.get. [\#199](https://github.com/ably/ably-ios/pull/199) ([tcard](https://github.com/tcard))
- Fix RTL3b [\#198](https://github.com/ably/ably-ios/pull/198) ([ricardopereira](https://github.com/ricardopereira))
- Product bundle consistency [\#197](https://github.com/ably/ably-ios/pull/197) ([ricardopereira](https://github.com/ricardopereira))
- RTL6e [\#196](https://github.com/ably/ably-ios/pull/196) ([ricardopereira](https://github.com/ricardopereira))
- RTL6i [\#194](https://github.com/ably/ably-ios/pull/194) ([ricardopereira](https://github.com/ricardopereira))
- RTL6a [\#193](https://github.com/ably/ably-ios/pull/193) ([ricardopereira](https://github.com/ricardopereira))
- RTL4f [\#192](https://github.com/ably/ably-ios/pull/192) ([ricardopereira](https://github.com/ricardopereira))
- RTL4e [\#190](https://github.com/ably/ably-ios/pull/190) ([ricardopereira](https://github.com/ricardopereira))
- RTL4c [\#188](https://github.com/ably/ably-ios/pull/188) ([ricardopereira](https://github.com/ricardopereira))
- RTL4b [\#187](https://github.com/ably/ably-ios/pull/187) ([ricardopereira](https://github.com/ricardopereira))
- RTL4a [\#186](https://github.com/ably/ably-ios/pull/186) ([ricardopereira](https://github.com/ricardopereira))
- Adjust {Rest, Realtime}.channels API to spec. [\#185](https://github.com/ably/ably-ios/pull/185) ([tcard](https://github.com/tcard))
- RTL3b [\#184](https://github.com/ably/ably-ios/pull/184) ([ricardopereira](https://github.com/ricardopereira))
- RTL3a [\#182](https://github.com/ably/ably-ios/pull/182) ([ricardopereira](https://github.com/ricardopereira))
- RTL1 [\#180](https://github.com/ably/ably-ios/pull/180) ([ricardopereira](https://github.com/ricardopereira))
- Rewrite ARTEventEmitter per the spec and adjust Connection. [\#179](https://github.com/ably/ably-ios/pull/179) ([tcard](https://github.com/tcard))
- RTS2 [\#178](https://github.com/ably/ably-ios/pull/178) ([ricardopereira](https://github.com/ricardopereira))
- Test suite enhancements [\#177](https://github.com/ably/ably-ios/pull/177) ([ricardopereira](https://github.com/ricardopereira))
- Swift test suite: renamed files with inconsistent names [\#176](https://github.com/ably/ably-ios/pull/176) ([ricardopereira](https://github.com/ricardopereira))
- RTN18c [\#175](https://github.com/ably/ably-ios/pull/175) ([ricardopereira](https://github.com/ricardopereira))
- RTN18b [\#174](https://github.com/ably/ably-ios/pull/174) ([ricardopereira](https://github.com/ricardopereira))
- Adjust stats API to spec. [\#173](https://github.com/ably/ably-ios/pull/173) ([tcard](https://github.com/tcard))
- Mark "RestClient initializer should accept a token" as pending. [\#172](https://github.com/ably/ably-ios/pull/172) ([tcard](https://github.com/tcard))
- Rename payload -\> data, refactor message data encoding. [\#171](https://github.com/ably/ably-ios/pull/171) ([tcard](https://github.com/tcard))
- Separate ARTProtocolMessage private parts. [\#170](https://github.com/ably/ably-ios/pull/170) ([tcard](https://github.com/tcard))
- Test suite websocket [\#169](https://github.com/ably/ably-ios/pull/169) ([ricardopereira](https://github.com/ricardopereira))
- RTN18a [\#168](https://github.com/ably/ably-ios/pull/168) ([ricardopereira](https://github.com/ricardopereira))
- RTN14b [\#167](https://github.com/ably/ably-ios/pull/167) ([ricardopereira](https://github.com/ricardopereira))
- Fix compiler warnings. [\#166](https://github.com/ably/ably-ios/pull/166) ([tcard](https://github.com/tcard))
- RTN14a [\#165](https://github.com/ably/ably-ios/pull/165) ([ricardopereira](https://github.com/ricardopereira))
- RSC10, RSC14c: Adapt to new spec, 40140 -\> \[40140, 40150\). [\#164](https://github.com/ably/ably-ios/pull/164) ([tcard](https://github.com/tcard))
- RTN12c [\#163](https://github.com/ably/ably-ios/pull/163) ([ricardopereira](https://github.com/ricardopereira))
- RTN12b [\#162](https://github.com/ably/ably-ios/pull/162) ([ricardopereira](https://github.com/ricardopereira))
- RTN12a [\#161](https://github.com/ably/ably-ios/pull/161) ([ricardopereira](https://github.com/ricardopereira))
- RTN10c [\#160](https://github.com/ably/ably-ios/pull/160) ([ricardopereira](https://github.com/ricardopereira))
- RTN10b [\#159](https://github.com/ably/ably-ios/pull/159) ([ricardopereira](https://github.com/ricardopereira))
- RSC1: Add token string constructor. [\#158](https://github.com/ably/ably-ios/pull/158) ([tcard](https://github.com/tcard))
- Make ARTPaginatedResult generic. [\#157](https://github.com/ably/ably-ios/pull/157) ([tcard](https://github.com/tcard))
- Remove bad RTN4e test, merge with RTN4d. [\#156](https://github.com/ably/ably-ios/pull/156) ([tcard](https://github.com/tcard))
- RTN10a [\#155](https://github.com/ably/ably-ios/pull/155) ([ricardopereira](https://github.com/ricardopereira))
- RTN7c [\#154](https://github.com/ably/ably-ios/pull/154) ([ricardopereira](https://github.com/ricardopereira))
- RTN7b [\#153](https://github.com/ably/ably-ios/pull/153) ([ricardopereira](https://github.com/ricardopereira))
- Xcode Project enhancements [\#152](https://github.com/ably/ably-ios/pull/152) ([ricardopereira](https://github.com/ricardopereira))
- Uncomment RSN4 test that now works. [\#151](https://github.com/ably/ably-ios/pull/151) ([tcard](https://github.com/tcard))
- Explicitly test RSN1. [\#150](https://github.com/ably/ably-ios/pull/150) ([tcard](https://github.com/tcard))
- Actually test RSA8c1. [\#149](https://github.com/ably/ably-ios/pull/149) ([tcard](https://github.com/tcard))
- Separate RSA3a test in HTTP and HTTPS. [\#148](https://github.com/ably/ably-ios/pull/148) ([tcard](https://github.com/tcard))
- RTL4: Fix test that was doing nothing. [\#147](https://github.com/ably/ably-ios/pull/147) ([tcard](https://github.com/tcard))
- RSL1c: check that it happens in a single request. [\#146](https://github.com/ably/ably-ios/pull/146) ([tcard](https://github.com/tcard))
- Test that getting the same channel name gives the same instance. [\#145](https://github.com/ably/ably-ios/pull/145) ([tcard](https://github.com/tcard))
- Temporarily disable RestClientStats tests. [\#144](https://github.com/ably/ably-ios/pull/144) ([tcard](https://github.com/tcard))
- Properly annotate ARTConnection.id, ARTConnection.key as optional. [\#141](https://github.com/ably/ably-ios/pull/141) ([tcard](https://github.com/tcard))
- waitUntil instead of toEventually in RTN9b test. [\#139](https://github.com/ably/ably-ios/pull/139) ([tcard](https://github.com/tcard))
- Don't use if-let to unwrap when it is sure that it will succeed. [\#138](https://github.com/ably/ably-ios/pull/138) ([tcard](https://github.com/tcard))
- Replace ?-chains with force-unwraps. [\#137](https://github.com/ably/ably-ios/pull/137) ([tcard](https://github.com/tcard))
- Use guard-let instead of if-let, ?-chaining and force-unwrapping. [\#136](https://github.com/ably/ably-ios/pull/136) ([tcard](https://github.com/tcard))
- Scan: test suite runner with Travis formatter [\#135](https://github.com/ably/ably-ios/pull/135) ([ricardopereira](https://github.com/ricardopereira))
- RTN7a [\#125](https://github.com/ably/ably-ios/pull/125) ([ricardopereira](https://github.com/ricardopereira))
- Realtime: test utilities enhancements [\#124](https://github.com/ably/ably-ios/pull/124) ([ricardopereira](https://github.com/ricardopereira))
- Auth.authorise: store TokenParams and AuthOptions [\#123](https://github.com/ably/ably-ios/pull/123) ([ricardopereira](https://github.com/ricardopereira))
- Payload data either as a JSON Object or Array [\#122](https://github.com/ably/ably-ios/pull/122) ([ricardopereira](https://github.com/ricardopereira))
- Meta: README & LICENSE [\#119](https://github.com/ably/ably-ios/pull/119) ([ricardopereira](https://github.com/ricardopereira))
- RTN9 [\#101](https://github.com/ably/ably-ios/pull/101) ([ricardopereira](https://github.com/ricardopereira))
- RTN8 [\#100](https://github.com/ably/ably-ios/pull/100) ([ricardopereira](https://github.com/ricardopereira))
- RTN6 [\#99](https://github.com/ably/ably-ios/pull/99) ([ricardopereira](https://github.com/ricardopereira))
- RTN5 [\#98](https://github.com/ably/ably-ios/pull/98) ([ricardopereira](https://github.com/ricardopereira))
- RSL4 [\#96](https://github.com/ably/ably-ios/pull/96) ([ricardopereira](https://github.com/ricardopereira))
- RSA10 [\#94](https://github.com/ably/ably-ios/pull/94) ([ricardopereira](https://github.com/ricardopereira))
- Query param: `access\_token` to `accessToken` [\#93](https://github.com/ably/ably-ios/pull/93) ([ricardopereira](https://github.com/ricardopereira))
- RSA9 [\#92](https://github.com/ably/ably-ios/pull/92) ([ricardopereira](https://github.com/ricardopereira))
- RSA8b [\#91](https://github.com/ably/ably-ios/pull/91) ([ricardopereira](https://github.com/ricardopereira))
- RSA8a [\#90](https://github.com/ably/ably-ios/pull/90) ([ricardopereira](https://github.com/ricardopereira))
- RSA15a [\#89](https://github.com/ably/ably-ios/pull/89) ([ricardopereira](https://github.com/ricardopereira))
- RSA3c [\#87](https://github.com/ably/ably-ios/pull/87) ([ricardopereira](https://github.com/ricardopereira))
- ObjC tests: Questionable API usage errors [\#86](https://github.com/ably/ably-ios/pull/86) ([ricardopereira](https://github.com/ricardopereira))
- Get Travis CI passing consistently  [\#85](https://github.com/ably/ably-ios/pull/85) ([ricardopereira](https://github.com/ricardopereira))
- Swift tests: Realtime [\#83](https://github.com/ably/ably-ios/pull/83) ([ricardopereira](https://github.com/ricardopereira))
- Swift tests: RestClient [\#82](https://github.com/ably/ably-ios/pull/82) ([ricardopereira](https://github.com/ricardopereira))
- Swift tests: Auth [\#81](https://github.com/ably/ably-ios/pull/81) ([ricardopereira](https://github.com/ricardopereira))
- Travis: XCTool [\#80](https://github.com/ably/ably-ios/pull/80) ([ricardopereira](https://github.com/ricardopereira))
- ObjC tests: ARTRestChannelPublishTest [\#77](https://github.com/ably/ably-ios/pull/77) ([ricardopereira](https://github.com/ricardopereira))
- ObjC tests: TimeForwards and TimeBackwards [\#76](https://github.com/ably/ably-ios/pull/76) ([ricardopereira](https://github.com/ricardopereira))
- ObjC tests: Review [\#75](https://github.com/ably/ably-ios/pull/75) ([ricardopereira](https://github.com/ricardopereira))
- Swift tests: Review [\#74](https://github.com/ably/ably-ios/pull/74) ([ricardopereira](https://github.com/ricardopereira))
- Swift tests: RSC14c [\#72](https://github.com/ably/ably-ios/pull/72) ([ricardopereira](https://github.com/ricardopereira))
- Swift tests: RSC14 [\#71](https://github.com/ably/ably-ios/pull/71) ([ricardopereira](https://github.com/ricardopereira))
- Swift tests: RSC9 [\#70](https://github.com/ably/ably-ios/pull/70) ([ricardopereira](https://github.com/ricardopereira))
- Travis: Freeze dependencies [\#67](https://github.com/ably/ably-ios/pull/67) ([ricardopereira](https://github.com/ricardopereira))
- ObjC tests: ARTRealtimeAttachTest [\#53](https://github.com/ably/ably-ios/pull/53) ([ricardopereira](https://github.com/ricardopereira))
- Travis [\#52](https://github.com/ably/ably-ios/pull/52) ([ricardopereira](https://github.com/ricardopereira))
- Presence\#history wasn't working \(infinite recursion\) [\#51](https://github.com/ably/ably-ios/pull/51) ([ricardopereira](https://github.com/ricardopereira))
- ObjC tests: fixed bad response [\#50](https://github.com/ably/ably-ios/pull/50) ([ricardopereira](https://github.com/ricardopereira))
- ObjC tests update to use the latest API [\#49](https://github.com/ably/ably-ios/pull/49) ([ricardopereira](https://github.com/ricardopereira))
- RTN4 [\#46](https://github.com/ably/ably-ios/pull/46) ([ricardopereira](https://github.com/ricardopereira))
- RTN3 [\#45](https://github.com/ably/ably-ios/pull/45) ([ricardopereira](https://github.com/ricardopereira))
- Connection proxy [\#43](https://github.com/ably/ably-ios/pull/43) ([ricardopereira](https://github.com/ricardopereira))
- RTC7 [\#42](https://github.com/ably/ably-ios/pull/42) ([ricardopereira](https://github.com/ricardopereira))
- RTC6 [\#40](https://github.com/ably/ably-ios/pull/40) ([ricardopereira](https://github.com/ricardopereira))
- RTC5 [\#39](https://github.com/ably/ably-ios/pull/39) ([ricardopereira](https://github.com/ricardopereira))
- RTC4, RTC4a [\#38](https://github.com/ably/ably-ios/pull/38) ([ricardopereira](https://github.com/ricardopereira))
- Timestamp fix [\#37](https://github.com/ably/ably-ios/pull/37) ([ricardopereira](https://github.com/ricardopereira))
- RTC1 done [\#35](https://github.com/ably/ably-ios/pull/35) ([ricardopereira](https://github.com/ricardopereira))
- Realtime transport error info [\#34](https://github.com/ably/ably-ios/pull/34) ([ricardopereira](https://github.com/ricardopereira))
- Realtime channels fixes [\#33](https://github.com/ably/ably-ios/pull/33) ([ricardopereira](https://github.com/ricardopereira))
- RTC1a, RTC1b, RTC1c [\#32](https://github.com/ably/ably-ios/pull/32) ([ricardopereira](https://github.com/ricardopereira))
- Realtime transport auth fixed \(RTC1\) [\#31](https://github.com/ably/ably-ios/pull/31) ([ricardopereira](https://github.com/ricardopereira))
- Client manage token requests [\#30](https://github.com/ably/ably-ios/pull/30) ([ricardopereira](https://github.com/ricardopereira))
- Auth.canRequestToken and Auth.validate revision [\#29](https://github.com/ably/ably-ios/pull/29) ([ricardopereira](https://github.com/ricardopereira))
- Auth Token specs [\#26](https://github.com/ably/ably-ios/pull/26) ([ricardopereira](https://github.com/ricardopereira))
- Converted tests to Swift 2 [\#25](https://github.com/ably/ably-ios/pull/25) ([ricardopereira](https://github.com/ricardopereira))
- Merged Yavor work, refactoring and RSA1 tests [\#23](https://github.com/ably/ably-ios/pull/23) ([ricardopereira](https://github.com/ricardopereira))
- Specs for ARTStats [\#19](https://github.com/ably/ably-ios/pull/19) ([fealebenpae](https://github.com/fealebenpae))
- Add spec for RestClient\#time \(RSC16\) [\#18](https://github.com/ably/ably-ios/pull/18) ([fealebenpae](https://github.com/fealebenpae))
- RestClient\#stats [\#17](https://github.com/ably/ably-ios/pull/17) ([fealebenpae](https://github.com/fealebenpae))
- BDD specs [\#16](https://github.com/ably/ably-ios/pull/16) ([fealebenpae](https://github.com/fealebenpae))
- Presence Map, Fallback and Exceptions [\#15](https://github.com/ably/ably-ios/pull/15) ([thevixac](https://github.com/thevixac))

## [0.7.0](https://github.com/ably/ably-ios/tree/0.7.0) (2015-04-29)
**Merged pull requests:**

- Token Auth and cryptography fixes and renaming [\#9](https://github.com/ably/ably-ios/pull/9) ([thevixac](https://github.com/thevixac))
- code examples in the readme [\#7](https://github.com/ably/ably-ios/pull/7) ([thevixac](https://github.com/thevixac))
- Ably ready for importing. [\#5](https://github.com/ably/ably-ios/pull/5) ([thevixac](https://github.com/thevixac))

\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
