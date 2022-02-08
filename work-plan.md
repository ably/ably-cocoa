# Scoping out the work needed to stabilise `ably-cocoa` tests

## Understanding the problem

### The symptoms

- We’ve had to disable a bunch of “flaky” tests
- Our CI jobs fail intermittently
- We have tests that:
    - fail
    - crash – this should _never_ happen. We should perhaps have that as an aim, so that:
        - we always have useful error messages 
        - we don’t get confusing test logs where it restarts the test run

#### Examples

- [This test run](https://github.com/ably/ably-cocoa/runs/5095831945?check_suite_focus=true) appears to have a crash in `PushTests.test__008__LocalDevice__has_a_device_method_that_returns_a_LocalDevice()` – it's a bit hard to discern from the test logs because I think that Prettier is hiding quite a bit. Like, the test run just ends, Xcode says there were 2 failures, Prettier says there was 1 (probably the 1 legit one and not the crash), and you get:

  >  Failing tests:
  > 3245
  > 	Ably-iOS-Tests:
  > 3246
  > 		PushTests.test__008__LocalDevice__has_a_device_method_that_returns_a_LocalDevice()
  
  But I get no information about the crash.

### Patterns

TODO Not sure; need to figure out how to discern. Like, how do I even get good information about failing tests out of GitHub?

- Is it all tests that can fail intermittently, or are there specific ones?
- Do they fail with similar errors each time?

### Possible causes

Possibly we shouldn’t be reusing channels - Marat is looking at this in #1280

- fixed timeouts that should be event-driven or something
- ?
- flaky sandbox environment

There’s also probably a test strategy issue – things that would be better off using mocks that are in fact using the network, but I’m hesitant about delving into that, it feels like a much deeper thing.

We know that we have tests that are dependent on order (#1241) – so e.g. a failure in one can trigger a failure in another – but if our aim is to have _no_ failing tests then this is immaterial. Ditto for things like shared state, which aren’t good _practice_ but unless we can point to a specific issue they're causing in terms of 100%-ness, should be out of the scope of the current test.

We (apparently) reuse channel names – Marat is working on this in #1282. Curious to see if this increases stability in reality.

We also have shared device registrations, with re-used channel names, in PushAdminTests.

## Other things we need to fix

- Fix the flaky tests

## Aims

- All current tests passing 100% of the time (e.g. you run the tests every hour and they pass for 2 days straight)
- All tests re-activated

## Plan for investigation

- Figure out best way to gather test failure data (Quintin suggested a platform e.g. a data lake but perhaps some scripts would suffice –depends on whether we see ourselves needing this in the future, which we might - he was coming at this from an observability angle, i.e. how are our tests doing?) Fastlane offers a bunch of output_types e.g. json / junit, but does it handle crashes? https://github.com/fastlane-community/trainer is able to generate JUnit files from `plist` / `xcresult`. (And it also recommends a Danger plugin that you can use to post results on the pull request.)
    - [Pete Steinberger about getting crash logs from xcodebuild](https://twitter.com/steipete/status/882207297216413696?lang=en) and [`xcpretty` not handling fatal errors](https://github.com/xcpretty/xcpretty/issues/291)
    - I’m a bit confused about `trainer`, I tried using it and got an error that it’s now built in to fastlane… but does that mean it’s being used to generate the JUnit output? [Looks like it, yes](https://github.com/fastlane/fastlane/blob/a5919aecbd4b5ff1631d2d5c916f7dd62f3c70dd/scan/lib/scan/runner.rb#L237-L245) – will confirm with verbose logging

- I wonder where the behaviour of re-launching the tests after a crash comes from? Is this an Xcode thing or a Scan thing? Do we want it?

- We need to be able to distinguish between crashes and other types of failure
    - Let's investigate by putting a deliberate crash in and see what we get in the logs
    - If we upload JUnit reports to somewhere central, can we attach the `xcodebuild` output (e.g. `xcresult`) too?

- [Some info about the `xcresult` format and how to extract things like crashes and assertion failures](https://prog.world/xcresult-how-and-why-to-read/)

- Let’s upload all artifacts to somewhere outside of GitHub so they’re there long-term

- Let's upload all of Fastlane’s generated files to see what useful things we get
  - We need to split out the example stuff and the Ably stuff

- We want to be able to get maximum information from GitHub logs - i.e. turn off xcpretty or figure out how to use xcodebuild-logs directory (but on e.g. [this run](https://github.com/ably/ably-cocoa/actions/runs/1807396292) there doesn’t seem to be any Ably-related stuff, is that a recent regression?) 

- Check that our tests are all running in the exact same conditions - same simulator, always from a clean slate, etc. (Also, we possibly shouldn’t restart after crash as long as we have tests that rely on previous tests having run - not sure how much control we have over that, though - we might need to just take it into account in the analysis.)

- I also need to find out why Fastlane is failing locally
  - It seems to work when run by `make`
  - Can't use iOS 12: `iOS 12.0 (12.0 - 16A366) - com.apple.CoreSimulator.SimRuntime.iOS-12-0 (unavailable, The iOS 12.0 simulator runtime is not supported on hosts after macOS 11.99.0.)` Seems the earliest allowed on my machine is 12.4
  - Ditto on GitHub actually: [macOS 10.15 virtual environment](https://github.com/actions/virtual-environments/blob/main/images/macos/macos-10.15-Readme.md)

- Understand whether the failing tests also fail in isolation.

## Getting correct simulator environments on GitHub Actions

https://github.com/actions/virtual-environments/blob/754215539971e726fa6989689246a2da00544c57/images/macos/macos-10.15-Readme.md

Their SDK support is tied in to Xcode versions (e.g. older SDKs only installed for older Xcodes…)

Our iOS deployment target is 10.0, which I believe we’ve not tested for a long time

The Readme says that:

> This SDK is compatible with projects that target:
> 
> - iOS 10.0+
> - tvOS 10.0+
> - macOS 10.12+

and that we do CI on all these versions, which certainly is not true.

GitHub Actions lowest versions:

- iOS 12.4 - Xcode 10.3
- iOS 13.2 - Xcode 11.2.1
- tvOS 12.4 - Xcode 10.3

What about latest versions? Might just use those for now for simplicity.

## Where might I store the data that comes out of GitHub, for further analysis?

I can't find much in the way of off-the-shelf analysis tools for JUnit tests. The closest seems to be [Jenkins’ Test Results Analyzer](https://plugins.jenkins.io/test-results-analyzer/) but not sure if that’s of use to us now.

Heroku has a 10k row limit (1GB), and we have 904 tests

- https://github.com/micrometer-metrics/micrometer/issues/1455

Maybe best thing for now would be to get this data into a database through a Sails + TypeORM app or something (I think I’d prefer to use that than Rails, and it’s a prototype anyway)

For running background jobs, I noticed that Ably’s Reactor Queues work as a message queue, I believe with Heroku integration (there’s a couple of open protocols it supports anyway, so just find some JS runner eg. Bull – I'm not sure if Sails has any inbuilt job support)

And then just set it up running in a loop in a CI job (up to 72 hours – although [my first attempt](https://github.com/ably/ably-cocoa/runs/5156594828?check_suite_focus=true) got terminated after seemingly 6 hours?)

It's probably important to also store the test logs, because I don't know what the JUnit stuff will tell us about:

- test execution order
- log messages telling us what was going on in the app leading up to the failure / crash

## What data to submit to observability server?

On top of what’s already there, I want to know:

- The OS version / lane name

## How might I analyse this sort of thing?

Is a time-series DB like InfluxDB / Prometheus (with a dashboard like e.g. Grafana) appropriate? I know little about this sort of thing. I don't think that ElasticSearch has anything to do with what I want.

**Probably would help if I knew what sort of querying I wanted to do.**

[A metrics suite for JUnit test code: a multiple case study on open source software](https://jserd.springeropen.com/articles/10.1186/s40411-014-0014-6) - no idea if this has anything to do with what I’m looking at

I also want to be able to assess overall trends - e.g. 
- know whether things like merging Marat’s unique channel name PR have improved things
- whether tests are getting more or less stable

I also want support for running a test multiple times in isolation once we’ve identified the worst-behaving, to see if it’s affected by other tests or not

Are there certain failures that usually occur together? Or at a particular time of day?

Would be good to show, against each upload, the number of new failures introduced

## JUnit file emitted by `trainer`

(Doing this locally.)

- Doesn't seem like I need to `mkdir` anything

- Failures are handled correctly - appear as a failure
- A force-unwrapped `nil` in the test file: runs trainer and generates JUnit, in which just appears as a failure (and Xcode continues with the rest of the test file, which it correctly reports):

  > <failure message="Crash: xctest (87881) UtilitiesTests.test__002__Utilities__JSON_Encoder__should_encode_a_protocol_message_that_has_invalid_data(). libsystem-sim_platform.dylib: CoreSimulator 783.5 - Device: iPhone 12 (3C9ADEA3-6A2F-48CC-ABB0-F3447B3202C1) - Runtime: iOS 14.4 (18D46) - DeviceType: iPhone 12
li> bswiftCore.dylib: Fatal error: Unexpectedly found nil while unwrapping an Optional value: file Ably_iOS_Tests/UtilitiesTests.swift, line 83
dy> ld: dyld4 config: DYLD_ROOT_PATH=/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 14.4.simruntime/Contents/Resources/RuntimeRoot DYLD_LIBRARY_PATH=/Users/lawrence/code/ably/ably-cocoa/derived_data/Build/Products/Debug-iphonesimulator DYLD_INSERT_LIBRARIES=/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 14.4.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libMainThreadChecker.dylib DYLD_FRAMEWORK_PATH=/Users/lawrence/code/ably/ably-cocoa/derived_data/Build/Products/Debug-iphonesimulator (#CharacterRangeLen=0)">
  >           </failure>

  The `xcresult` file contains the full crash log as an attachment (including numbered lines).

  There are https://github.com/fastlane-community/trainer/issues/42 and https://github.com/fastlane-community/trainer/issues/26 for taking advantage of these attachments.

- Exceptions thrown in the code (added one to `-[ARTMessage messageSize]`) – doesn’t run trainer / generate JUnit. But then a second time it seemed to? It just has the name of the exception and its message, and one line of stack trace (and some random stuff after that hash at the end). Also it doesn’t seem to re-launch the test suite after a failure, which is different to behaviour I was seeing when we saw real-life CI crashes…
  > <failure message="unexpected exception raised: Deliberate Lawrence exception
  > (/Users/lawrence/code/ably/ably-cocoa/Spec/Tests/UtilitiesTests.swift#CharacterRangeLen=0&amp;EndingLineNumber=481&amp;StartingLineNumber=481)">
  > </failure>

  Ah - I think that's because it's happening inside a _test assertion_, which seems to catch the exception (and XCTest’s assertions do a similar thing `XCTAssertEqual failed: throwing "Deliberate Lawrence exception"`) Let's see if we don’t do it inside an assertion.

  Then you get

  >             <failure message="Deliberate Lawrence exception (NSInternalInconsistencyException) (/Users/lawrence/code/ably/ably-cocoa/Spec/Tests/UtilitiesTests.swift#CharacterRangeLen=0&amp;EndingLineNumber=480&amp;StartingLineNumber=480)">
  >          </failure>

  and it still doesn’t restart afterwards - must be handled by XCTest internally

  The `.xcresult` file just treats it as a failure (no crash log attachment) - Says "Uncaught exception at …" though

Ideally we’d submit the `xcresult` file to our observability thing, and then do what we want with them later, but I think that `trainer` uses `xcresulttool` which is macOS.

### Missing JUnit reports

- We seem to have some situations in which the tests fail and a `.junit` file _isn’t_ emitted - e.g. [this test run](https://github.com/ably/ably-cocoa/runs/5147301451?check_suite_focus=true). But when I was trying things out locally, it always generated a `.junit` report, whatever kind of failure I threw at it.

It’s actually happening plenty of times. Only seems to happen on the first iteration of the loop – i.e. if the first iteration generates a report, seems like all the subsequent ones do, too.

Okay, let's look at some and try to figure out how these reports differ.

```sql
select uploads.id, iteration from uploads join failures on (uploads.id = failures.upload_id) where iteration=1;
```

shows that I don't have any uploads with a failure on iteration 1 - i.e. every time the tests fail on the first iteration, there's no test report

- Failed on first run, failed to generate: https://github.com/ably/ably-cocoa/actions/runs/1853368755/attempts/8

```
2022-02-17T12:16:51.0155310Z INFO [2022-02-17 12:16:51.01]: [32mSuccessfully loaded '/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/Scanfile' 📄[0m
2022-02-17T12:16:51.0155570Z 
2022-02-17T12:16:51.0173340Z +----------------------+---------------------+
2022-02-17T12:16:51.0173750Z | Detected Values from './fastlane/Scanfile' |
2022-02-17T12:16:51.0174100Z +----------------------+---------------------+
2022-02-17T12:16:51.0174380Z | open_report          | false               |
2022-02-17T12:16:51.0174580Z | clean                | false               |
2022-02-17T12:16:51.0174790Z | skip_slack           | true                |
2022-02-17T12:16:51.0175000Z | output_style         | raw                 |
2022-02-17T12:16:51.0175320Z | result_bundle        | true                |
2022-02-17T12:16:51.0175610Z | output_types         | junit               |
2022-02-17T12:16:51.0175840Z | ensure_devices_found | true                |
2022-02-17T12:16:51.0176170Z +----------------------+---------------------+
```

and then

```
2022-02-17T12:16:55.2663980Z +------------------------------------------------+-----------------------------------------------------+
2022-02-17T12:16:55.2665030Z |                                       [32mSummary for scan 2.204.2[0m                                       |
2022-02-17T12:16:55.2665880Z +------------------------------------------------+-----------------------------------------------------+
2022-02-17T12:16:55.2667580Z | scheme                                         | Ably-iOS-Tests                                      |
2022-02-17T12:16:55.2668160Z | derived_data_path                              | derived_data                                        |
2022-02-17T12:16:55.2668640Z | devices                                        | ["iPhone 12 (14.4)"]                                |
2022-02-17T12:16:55.2669110Z | test_without_building                          | false                                               |
2022-02-17T12:16:55.2669920Z | xcargs                                         | ABLY_ENV=sandbox CLANG_ANALYZER_OUTPUT=plist-html   |
2022-02-17T12:16:55.2670980Z | output_directory                               | fastlane/test_output/sdk/test_iOS14_4               |
2022-02-17T12:16:55.2671490Z | project                                        | ./Ably.xcodeproj                                    |
2022-02-17T12:16:55.2675460Z | skip_detect_devices                            | false                                               |
2022-02-17T12:16:55.2675780Z | ensure_devices_found                           | true                                                |
2022-02-17T12:16:55.2676040Z | force_quit_simulator                           | false                                               |
2022-02-17T12:16:55.2676310Z | reset_simulator                                | false                                               |
2022-02-17T12:16:55.2676570Z | disable_slide_to_type                          | true                                                |
2022-02-17T12:16:55.2676830Z | reinstall_app                                  | false                                               |
2022-02-17T12:16:55.2677090Z | clean                                          | false                                               |
2022-02-17T12:16:55.2677350Z | open_report                                    | false                                               |
2022-02-17T12:16:55.2677600Z | output_style                                   | raw                                                 |
2022-02-17T12:16:55.2677860Z | output_types                                   | junit                                               |
2022-02-17T12:16:55.2678240Z | buildlog_path                                  | ~/Library/Logs/scan                                 |
2022-02-17T12:16:55.2678510Z | include_simulator_logs                         | false                                               |
2022-02-17T12:16:55.2678790Z | output_remove_retry_attempts                   | false                                               |
2022-02-17T12:16:55.2679070Z | should_zip_build_products                      | false                                               |
2022-02-17T12:16:55.2679340Z | output_xctestrun                               | false                                               |
2022-02-17T12:16:55.2679590Z | result_bundle                                  | true                                                |
2022-02-17T12:16:55.2679860Z | use_clang_report_name                          | false                                               |
2022-02-17T12:16:55.2680140Z | disable_concurrent_testing                     | false                                               |
2022-02-17T12:16:55.2680390Z | skip_build                                     | false                                               |
2022-02-17T12:16:55.2680670Z | slack_use_webhook_configured_username_and_icon | false                                               |
2022-02-17T12:16:55.2680950Z | slack_username                                 | fastlane                                            |
2022-02-17T12:16:55.2681260Z | slack_icon_url                                 | https://fastlane.tools/assets/img/fastlane_icon.png |
2022-02-17T12:16:55.2681560Z | skip_slack                                     | true                                                |
2022-02-17T12:16:55.2681820Z | slack_only_on_failure                          | false                                               |
2022-02-17T12:16:55.2682460Z | xcodebuild_command                             | env NSUnbufferedIO=YES xcodebuild                   |
2022-02-17T12:16:55.2682830Z | skip_package_dependencies_resolution           | false                                               |
2022-02-17T12:16:55.2683210Z | disable_package_automatic_updates              | false                                               |
2022-02-17T12:16:55.2683530Z | use_system_scm                                 | false                                               |
2022-02-17T12:16:55.2683850Z | number_of_retries                              | 0                                                   |
2022-02-17T12:16:55.2684480Z | fail_build                                     | true                                                |
2022-02-17T12:16:55.2684780Z | xcode_path                                     | /Applications/Xcode_12.4.app                        |
2022-02-17T12:16:55.2685390Z +------------------------------------------------+-----------------------------------------------------+
```

and then

```
2022-02-17T12:24:09.9224540Z INFO [2022-02-17 12:24:09.92]: ▸ [35mTest Case '-[Ably_iOS_Tests.RealtimeClientPresenceTests test__015__Presence__subscribe__with_no_arguments_should_subscribe_a_listener_to_all_presence_messages]' started.[0m
2022-02-17T12:24:10.4731800Z INFO [2022-02-17 12:24:10.47]: ▸ [35m2022-02-17 12:24:10.471574+0000 xctest[12104:103683] WARN: RT:0x7fd8f117bc40 connection "I4Ig0Itr7p" has reconnected, but resume failed. Reattaching any attached channels[0m
2022-02-17T12:24:11.4735140Z INFO [2022-02-17 12:24:11.47]: ▸ [35m/Users/runner/work/ably-cocoa/ably-cocoa/Spec/Tests/RealtimeClientPresenceTests.swift:536: error: -[Ably_iOS_Tests.RealtimeClientPresenceTests test__015__Presence__subscribe__with_no_arguments_should_subscribe_a_listener_to_all_presence_messages] : expected to equal <Enter>, got <Present>[0m
```

and then

```
2022-02-17T12:30:29.0497920Z Test Suite 'Ably-iOS-Tests.xctest' failed at 2022-02-17 12:30:21.832.
2022-02-17T12:30:29.0498060Z 	 Executed 904 tests, with 1 failure (0 unexpected) in 683.026 (684.164) seconds
2022-02-17T12:30:29.0498280Z Test Suite 'All tests' failed at 2022-02-17 12:30:21.835.
2022-02-17T12:30:29.0498410Z 	 Executed 904 tests, with 1 failure (0 unexpected) in 683.026 (684.170) seconds
2022-02-17T12:30:29.0498760Z 2022-02-17 12:30:24.818 xcodebuild[8872:54874] [MT] IDETestOperationsObserverDebug: 706.166 elapsed -- Testing started completed.
2022-02-17T12:30:29.0499080Z 2022-02-17 12:30:24.818 xcodebuild[8872:54874] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2022-02-17T12:30:29.0499400Z 2022-02-17 12:30:24.818 xcodebuild[8872:54874] [MT] IDETestOperationsObserverDebug: 706.166 sec, +706.166 sec -- end
2022-02-17T12:30:29.0499500Z Failing tests:
2022-02-17T12:30:29.0499650Z 	Ably-iOS-Tests:
2022-02-17T12:30:29.0499880Z 		RealtimeClientPresenceTests.test__015__Presence__subscribe__with_no_arguments_should_subscribe_a_listener_to_all_presence_messages()
2022-02-17T12:30:29.0499900Z 
2022-02-17T12:30:29.0499970Z ** TEST FAILED **
2022-02-17T12:30:29.0499980Z 
2022-02-17T12:30:29.0499990Z 
2022-02-17T12:30:29.0500090Z Test session results, code coverage, and logs:
2022-02-17T12:30:29.0500410Z 	/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/test_output/sdk/test_iOS14_4/Ably-iOS-Tests.xcresult
2022-02-17T12:30:29.0500620Z ERROR [2022-02-17 12:30:27.99]: [31mExit status: 65[0m
2022-02-17T12:30:29.0500900Z ERROR [2022-02-17 12:30:27.99]: [31mYour shell environment is not correctly configured[0m
2022-02-17T12:30:29.0501160Z ERROR [2022-02-17 12:30:27.99]: [31mInstead of UTF-8 your shell uses US-ASCII[0m
2022-02-17T12:30:29.0501420Z ERROR [2022-02-17 12:30:27.99]: [31mPlease add the following to your '~/.bashrc':[0m
2022-02-17T12:30:29.0501600Z ERROR [2022-02-17 12:30:27.99]: 
2022-02-17T12:30:29.0501820Z ERROR [2022-02-17 12:30:27.99]: [31m       export LANG=en_US.UTF-8[0m
2022-02-17T12:30:29.0502050Z ERROR [2022-02-17 12:30:27.99]: [31m       export LANGUAGE=en_US.UTF-8[0m
2022-02-17T12:30:29.0502420Z ERROR [2022-02-17 12:30:27.99]: [31m       export LC_ALL=en_US.UTF-8[0m
2022-02-17T12:30:29.0502650Z ERROR [2022-02-17 12:30:27.99]: 
2022-02-17T12:30:29.0502960Z ERROR [2022-02-17 12:30:27.99]: [31mYou'll have to restart your shell session after updating the file.[0m
2022-02-17T12:30:29.0503280Z ERROR [2022-02-17 12:30:27.99]: [31mIf you are using zshell or another shell, make sure to edit the correct bash file.[0m
2022-02-17T12:30:29.0503560Z ERROR [2022-02-17 12:30:27.99]: [31mFor more information visit this stackoverflow answer:[0m
2022-02-17T12:30:29.0503830Z ERROR [2022-02-17 12:30:27.99]: [31mhttps://stackoverflow.com/a/17031697/445598[0m
2022-02-17T12:30:29.0504350Z WARN [2022-02-17 12:30:28.08]: [33m[33mLane Context:[0m
2022-02-17T12:30:29.0505090Z INFO [2022-02-17 12:30:28.08]: {:DEFAULT_PLATFORM=>:ios, :PLATFORM_NAME=>:ios, :LANE_NAME=>"ios test_iOS14_4", :SCAN_GENERATED_XCRESULT_PATH=>"/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/test_output/sdk/test_iOS14_4/Ably-iOS-Tests.xcresult", :SCAN_DERIVED_DATA_PATH=>"derived_data", :SCAN_GENERATED_PLIST_FILES=>[], :SCAN_GENERATED_PLIST_FILE=>nil}
2022-02-17T12:30:29.0505380Z ERROR [2022-02-17 12:30:28.08]: [31mError building/testing the application. See the log above.[0m
2022-02-17T12:30:29.0505770Z INFO [2022-02-17 12:30:28.08]: [32mSuccessfully generated documentation at path '/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/README.md'[0m
2022-02-17T12:30:29.0505770Z 
2022-02-17T12:30:29.0505960Z +------+------------------+-------------+
2022-02-17T12:30:29.0506150Z |           [32mfastlane summary[0m            |
2022-02-17T12:30:29.0506330Z +------+------------------+-------------+
2022-02-17T12:30:29.0506420Z | Step | Action           | Time (in s) |
2022-02-17T12:30:29.0506600Z +------+------------------+-------------+
2022-02-17T12:30:29.0506700Z | 1    | default_platform | 0           |
2022-02-17T12:30:29.0506930Z | 💥   | [31mrun_tests[0m        | 817         |
2022-02-17T12:30:29.0507110Z +------+------------------+-------------+
2022-02-17T12:30:29.0507110Z 
2022-02-17T12:30:29.0507360Z ERROR [2022-02-17 12:30:28.26]: [31mfastlane finished with errors[0m
2022-02-17T12:30:29.0507360Z 
2022-02-17T12:30:29.0507460Z #######################################################################
2022-02-17T12:30:29.0507570Z # fastlane 2.204.3 is available. You are on 2.204.2.
2022-02-17T12:30:29.0507670Z # You should use the latest version.
2022-02-17T12:30:29.0507790Z # Please update using `bundle update fastlane`.
2022-02-17T12:30:29.0507890Z #######################################################################
2022-02-17T12:30:29.0507890Z 
2022-02-17T12:30:29.0508070Z [32m2.204.3 Improvements[0m
2022-02-17T12:30:29.0508280Z * [trainer][scan] identify skipped tests in `xcresult` and export to Junit format and output in scan (#19957) via Igor Makarov
2022-02-17T12:30:29.0508410Z * [Fastlane.Swift] Swift fastlane upgrader #18933 (#19914) via Enrique Garcia
2022-02-17T12:30:29.0508580Z * [pem][spaceship] update development push certificate type ID (#19879) via Igor Makarov
2022-02-17T12:30:29.0508720Z * [snapshot] fix compile error on macCatalyst (#19917) via Philipp Arndt
2022-02-17T12:30:29.0508880Z * [Fastlane.Swift] readPodspec: return map of [String: Any] (#19953) via Hais Deakin
2022-02-17T12:30:29.0509040Z * [match] update :force_for_new_certificates option description (#19938) via Wolfgang Lutz
2022-02-17T12:30:29.0509050Z 
2022-02-17T12:30:29.0509270Z [32mPlease update using `bundle update fastlane`[0m
2022-02-17T12:30:29.2215940Z bundler: failed to load command: fastlane (/usr/local/lib/ruby/gems/2.7.0/bin/fastlane)
2022-02-17T12:30:29.2249120Z /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/interface.rb:163:in `build_failure!': \e[31m[!] Error building/testing the application. See the log above.\e[0m (FastlaneCore::Interface::FastlaneBuildFailure)
2022-02-17T12:30:29.2250630Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/ui.rb:17:in `method_missing'
2022-02-17T12:30:29.2252190Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/error_handler.rb:55:in `handle_build_error'
2022-02-17T12:30:29.2253180Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:93:in `block in execute'
2022-02-17T12:30:29.2254170Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/command_executor.rb:84:in `execute'
2022-02-17T12:30:29.2255080Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:80:in `execute'
2022-02-17T12:30:29.2255940Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:56:in `test_app'
2022-02-17T12:30:29.2257070Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:24:in `run'
2022-02-17T12:30:29.2257950Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/manager.rb:23:in `work'
2022-02-17T12:30:29.2258850Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/run_tests.rb:17:in `run'
2022-02-17T12:30:29.2259890Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:263:in `block (2 levels) in execute_action'
2022-02-17T12:30:29.2260940Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/actions_helper.rb:69:in `execute_action'
2022-02-17T12:30:29.2261980Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:255:in `block in execute_action'
2022-02-17T12:30:29.2262940Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `chdir'
2022-02-17T12:30:29.2263870Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `execute_action'
2022-02-17T12:30:29.2264840Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:157:in `trigger_action_by_name'
2022-02-17T12:30:29.2265790Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/fast_file.rb:159:in `method_missing'
2022-02-17T12:30:29.2266400Z 	from Fastfile:16:in `block (2 levels) in parsing_binding'
2022-02-17T12:30:29.2267200Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane.rb:33:in `call'
2022-02-17T12:30:29.2268380Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:49:in `block in execute'
2022-02-17T12:30:29.2269350Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `chdir'
2022-02-17T12:30:29.2270280Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `execute'
2022-02-17T12:30:29.2271210Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane_manager.rb:47:in `cruise_lane'
2022-02-17T12:30:29.2272180Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/command_line_handler.rb:36:in `handle'
2022-02-17T12:30:29.2273220Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:109:in `block (2 levels) in run'
2022-02-17T12:30:29.2274140Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:187:in `call'
2022-02-17T12:30:29.2274980Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:157:in `run'
2022-02-17T12:30:29.2276150Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/runner.rb:444:in `run_active_command'
2022-02-17T12:30:29.2277150Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/fastlane_runner.rb:124:in `run!'
2022-02-17T12:30:29.2278270Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/delegates.rb:18:in `run!'
2022-02-17T12:30:29.2279150Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:353:in `run'
2022-02-17T12:30:29.2281170Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:42:in `start'
2022-02-17T12:30:29.2281830Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/cli_tools_distributor.rb:122:in `take_off'
2022-02-17T12:30:29.2282340Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/bin/fastlane:23:in `<top (required)>'
2022-02-17T12:30:29.2282660Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `load'
2022-02-17T12:30:29.2282940Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `<top (required)>'
2022-02-17T12:30:29.2283390Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli/exec.rb:58:in `load'
2022-02-17T12:30:29.2287310Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli/exec.rb:58:in `kernel_load'
2022-02-17T12:30:29.2287890Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli/exec.rb:23:in `run'
2022-02-17T12:30:29.2288370Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli.rb:484:in `exec'
2022-02-17T12:30:29.2288880Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor/command.rb:27:in `run'
2022-02-17T12:30:29.2289430Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor/invocation.rb:127:in `invoke_command'
2022-02-17T12:30:29.2289970Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor.rb:392:in `dispatch'
2022-02-17T12:30:29.2290460Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli.rb:31:in `dispatch'
2022-02-17T12:30:29.2290940Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor/base.rb:485:in `start'
2022-02-17T12:30:29.2291420Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli.rb:25:in `start'
2022-02-17T12:30:29.2291890Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/exe/bundle:48:in `block in <top (required)>'
2022-02-17T12:30:29.2292430Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/friendly_errors.rb:103:in `with_friendly_errors'
2022-02-17T12:30:29.2292910Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/exe/bundle:36:in `<top (required)>'
2022-02-17T12:30:29.2293210Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `load'
2022-02-17T12:30:29.2293480Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `<main>'
2022-02-17T12:30:29.2294340Z /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/interface.rb:163:in `build_failure!': Error building/testing the application. See the log above. (FastlaneCore::Interface::FastlaneBuildFailure)
2022-02-17T12:30:29.2295050Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/ui.rb:17:in `method_missing'
2022-02-17T12:30:29.2295600Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/error_handler.rb:55:in `handle_build_error'
2022-02-17T12:30:29.2296100Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:93:in `block in execute'
2022-02-17T12:30:29.2296650Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/command_executor.rb:84:in `execute'
2022-02-17T12:30:29.2297160Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:80:in `execute'
2022-02-17T12:30:29.2297620Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:56:in `test_app'
2022-02-17T12:30:29.2298100Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:24:in `run'
2022-02-17T12:30:29.2298560Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/manager.rb:23:in `work'
2022-02-17T12:30:29.2299060Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/run_tests.rb:17:in `run'
2022-02-17T12:30:29.2299630Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:263:in `block (2 levels) in execute_action'
2022-02-17T12:30:29.2300560Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/actions_helper.rb:69:in `execute_action'
2022-02-17T12:30:29.2301210Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:255:in `block in execute_action'
2022-02-17T12:30:29.2301720Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `chdir'
2022-02-17T12:30:29.2302230Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `execute_action'
2022-02-17T12:30:29.2302770Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:157:in `trigger_action_by_name'
2022-02-17T12:30:29.2303520Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/fast_file.rb:159:in `method_missing'
2022-02-17T12:30:29.2303860Z 	from Fastfile:16:in `block (2 levels) in parsing_binding'
2022-02-17T12:30:29.2304320Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane.rb:33:in `call'
2022-02-17T12:30:29.2304830Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:49:in `block in execute'
2022-02-17T12:30:29.2305340Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `chdir'
2022-02-17T12:30:29.2305840Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `execute'
2022-02-17T12:30:29.2306350Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane_manager.rb:47:in `cruise_lane'
2022-02-17T12:30:29.2306900Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/command_line_handler.rb:36:in `handle'
2022-02-17T12:30:29.2307480Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:109:in `block (2 levels) in run'
2022-02-17T12:30:29.2308000Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:187:in `call'
2022-02-17T12:30:29.2308460Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:157:in `run'
2022-02-17T12:30:29.2308960Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/runner.rb:444:in `run_active_command'
2022-02-17T12:30:29.2309500Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/fastlane_runner.rb:124:in `run!'
2022-02-17T12:30:29.2310000Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/delegates.rb:18:in `run!'
2022-02-17T12:30:29.2310520Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:353:in `run'
2022-02-17T12:30:29.2311050Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:42:in `start'
2022-02-17T12:30:29.2311590Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/cli_tools_distributor.rb:122:in `take_off'
2022-02-17T12:30:29.2312090Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/bin/fastlane:23:in `<top (required)>'
2022-02-17T12:30:29.2312410Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `load'
2022-02-17T12:30:29.2312690Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `<top (required)>'
2022-02-17T12:30:29.2313140Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli/exec.rb:58:in `load'
2022-02-17T12:30:29.2313620Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli/exec.rb:58:in `kernel_load'
2022-02-17T12:30:29.2314390Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli/exec.rb:23:in `run'
2022-02-17T12:30:29.2314870Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli.rb:484:in `exec'
2022-02-17T12:30:29.2315370Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor/command.rb:27:in `run'
2022-02-17T12:30:29.2316120Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor/invocation.rb:127:in `invoke_command'
2022-02-17T12:30:29.2316720Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor.rb:392:in `dispatch'
2022-02-17T12:30:29.2317200Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli.rb:31:in `dispatch'
2022-02-17T12:30:29.2317690Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/vendor/thor/lib/thor/base.rb:485:in `start'
2022-02-17T12:30:29.2318150Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/cli.rb:25:in `start'
2022-02-17T12:30:29.2318810Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/exe/bundle:48:in `block in <top (required)>'
2022-02-17T12:30:29.2319330Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/lib/bundler/friendly_errors.rb:103:in `with_friendly_errors'
2022-02-17T12:30:29.2319800Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.7/exe/bundle:36:in `<top (required)>'
2022-02-17T12:30:29.2320110Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `load'
2022-02-17T12:30:29.2320440Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `<main>'
```

So let's compare it to a test that fails on the second iteration:

```
test-observability::DATABASE=> select uploads.id, iteration, test_class_name, test_case_name from uploads join failures on (uploads.id = failures.upload_id) join test_cases on (failures.test_case_id = test_cases.id) where iteration=2;
                  id                  | iteration |        test_class_name        |                                                         test_case_name
--------------------------------------+-----------+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------
 3b632eca-87e3-4b56-ba65-aac0899c5548 |         2 | RestClientTests               | test__014__RestClient__client_should_handle_error_messages_in_plaintext_and_HTML_format()
 254cd409-b3bd-42d2-a465-961574cba8f8 |         2 | PushTests                     | test__008__LocalDevice__has_a_device_method_that_returns_a_LocalDevice()
 9bdb880b-ea17-4771-8a57-4c458b02ad7d |         2 | RealtimeClientPresenceTests   | test__078__Presence__enter__optional_data_can_be_included_when_entering_a_channel()
 2165bf1c-f017-4f8f-a583-9990f205f917 |         2 | RealtimeClientConnectionTests | test__088__Connection__Host_Fallback__applies_when_the_default_realtime_ably_io_endpoint_is_being_used()
 2165bf1c-f017-4f8f-a583-9990f205f917 |         2 | RealtimeClientConnectionTests | test__092__Connection__Host_Fallback__should_retry_hosts_in_random_order_after_checkin_if_an_internet_connection_is_available()
```

So, https://test-observability.herokuapp.com/uploads/2165bf1c-f017-4f8f-a583-9990f205f917 is https://github.com/ably/ably-cocoa/actions/runs/1844651330/attempts/9:

```
2022-02-16T12:51:06.4260230Z INFO [2022-02-16 12:51:06.42]: [32mSuccessfully loaded '/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/Scanfile' 📄[0m
2022-02-16T12:51:06.4261600Z 
2022-02-16T12:51:06.4277710Z +----------------------+---------------------+
2022-02-16T12:51:06.4278120Z | Detected Values from './fastlane/Scanfile' |
2022-02-16T12:51:06.4278450Z +----------------------+---------------------+
2022-02-16T12:51:06.4278700Z | open_report          | false               |
2022-02-16T12:51:06.4278900Z | clean                | false               |
2022-02-16T12:51:06.4279100Z | skip_slack           | true                |
2022-02-16T12:51:06.4279330Z | output_style         | raw                 |
2022-02-16T12:51:06.4279530Z | result_bundle        | true                |
2022-02-16T12:51:06.4279740Z | output_types         | junit               |
2022-02-16T12:51:06.4279950Z | ensure_devices_found | true                |
2022-02-16T12:51:06.4280270Z +----------------------+---------------------+
```

and then

```
2022-02-16T12:51:10.5879520Z +------------------------------------------------+-----------------------------------------------------+
2022-02-16T12:51:10.5880920Z |                                       [32mSummary for scan 2.204.2[0m                                       |
2022-02-16T12:51:10.5881660Z +------------------------------------------------+-----------------------------------------------------+
2022-02-16T12:51:10.5882800Z | scheme                                         | Ably-iOS-Tests                                      |
2022-02-16T12:51:10.5883100Z | derived_data_path                              | derived_data                                        |
2022-02-16T12:51:10.5883360Z | devices                                        | ["iPhone 12 (14.4)"]                                |
2022-02-16T12:51:10.5884710Z | test_without_building                          | false                                               |
2022-02-16T12:51:10.5885170Z | xcargs                                         | ABLY_ENV=sandbox CLANG_ANALYZER_OUTPUT=plist-html   |
2022-02-16T12:51:10.5885610Z | output_directory                               | fastlane/test_output/sdk/test_iOS14_4               |
2022-02-16T12:51:10.5885910Z | project                                        | ./Ably.xcodeproj                                    |
2022-02-16T12:51:10.5886400Z | skip_detect_devices                            | false                                               |
2022-02-16T12:51:10.5886670Z | ensure_devices_found                           | true                                                |
2022-02-16T12:51:10.5886930Z | force_quit_simulator                           | false                                               |
2022-02-16T12:51:10.5887180Z | reset_simulator                                | false                                               |
2022-02-16T12:51:10.5887450Z | disable_slide_to_type                          | true                                                |
2022-02-16T12:51:10.5887710Z | reinstall_app                                  | false                                               |
2022-02-16T12:51:10.5887940Z | clean                                          | false                                               |
2022-02-16T12:51:10.5888190Z | open_report                                    | false                                               |
2022-02-16T12:51:10.5888440Z | output_style                                   | raw                                                 |
2022-02-16T12:51:10.5888680Z | output_types                                   | junit                                               |
2022-02-16T12:51:10.5889190Z | buildlog_path                                  | ~/Library/Logs/scan                                 |
2022-02-16T12:51:10.5889490Z | include_simulator_logs                         | false                                               |
2022-02-16T12:51:10.5889770Z | output_remove_retry_attempts                   | false                                               |
2022-02-16T12:51:10.5890030Z | should_zip_build_products                      | false                                               |
2022-02-16T12:51:10.5890290Z | output_xctestrun                               | false                                               |
2022-02-16T12:51:10.5890540Z | result_bundle                                  | true                                                |
2022-02-16T12:51:10.5890790Z | use_clang_report_name                          | false                                               |
2022-02-16T12:51:10.5891060Z | disable_concurrent_testing                     | false                                               |
2022-02-16T12:51:10.5891640Z | skip_build                                     | false                                               |
2022-02-16T12:51:10.5892180Z | slack_use_webhook_configured_username_and_icon | false                                               |
2022-02-16T12:51:10.5892530Z | slack_username                                 | fastlane                                            |
2022-02-16T12:51:10.5892840Z | slack_icon_url                                 | https://fastlane.tools/assets/img/fastlane_icon.png |
2022-02-16T12:51:10.5893120Z | skip_slack                                     | true                                                |
2022-02-16T12:51:10.5893380Z | slack_only_on_failure                          | false                                               |
2022-02-16T12:51:10.5893670Z | xcodebuild_command                             | env NSUnbufferedIO=YES xcodebuild                   |
2022-02-16T12:51:10.5893970Z | skip_package_dependencies_resolution           | false                                               |
2022-02-16T12:51:10.5894260Z | disable_package_automatic_updates              | false                                               |
2022-02-16T12:51:10.5894790Z | use_system_scm                                 | false                                               |
2022-02-16T12:51:10.5895760Z | number_of_retries                              | 0                                                   |
2022-02-16T12:51:10.5896140Z | fail_build                                     | true                                                |
2022-02-16T12:51:10.5896410Z | xcode_path                                     | /Applications/Xcode_12.4.app                        |
2022-02-16T12:51:10.5897120Z +------------------------------------------------+-----------------------------------------------------+
```

and then (2 failures):

```
2022-02-16T12:57:15.0111520Z INFO [2022-02-16 12:57:15.01]: ▸ [35mTest Case '-[Ably_iOS_Tests.RealtimeClientConnectionTests test__088__Connection__Host_Fallback__applies_when_the_default_realtime_ably_io_endpoint_is_being_used]' started.[0m
2022-02-16T12:57:16.5097140Z INFO [2022-02-16 12:57:16.50]: ▸ [35m/Users/runner/work/ably-cocoa/ably-cocoa/Spec/Tests/RealtimeClientConnectionTests.swift:3474: error: -[Ably_iOS_Tests.RealtimeClientConnectionTests test__088__Connection__Host_Fallback__applies_when_the_default_realtime_ably_io_endpoint_is_being_used] : expected to have Array<URL> with count 2, got 1[0m
```

```
2022-02-16T13:04:14.4525780Z Test Case '-[Ably_iOS_Tests.RealtimeClientConnectionTests test__092__Connection__Host_Fallback__should_retry_hosts_in_random_order_after_checkin_if_an_internet_connection_is_available]' started.
2022-02-16T13:04:14.4526830Z /Users/runner/work/ably-cocoa/ably-cocoa/Spec/Tests/RealtimeClientConnectionTests.swift:3755: error: -[Ably_iOS_Tests.RealtimeClientConnectionTests test__092__Connection__Host_Fallback__should_retry_hosts_in_random_order_after_checkin_if_an_internet_connection_is_available] : expected to equal <[d.ably-realtime.com, e.ably-realtime.com, a.ably-realtime.com, c.ably-realtime.com, b.ably-realtime.com]>, got <[d.ably-realtime.com, e.ably-realtime.com, a.ably-realtime.com, c.ably-realtime.com]>
2022-02-16T13:04:14.4526860Z 
2022-02-16T13:04:14.4527370Z Test Case '-[Ably_iOS_Tests.RealtimeClientConnectionTests test__092__Connection__Host_Fallback__should_retry_hosts_in_random_order_after_checkin_if_an_internet_connection_is_available]' failed (1.015 seconds).
```

and then

```
2022-02-16T13:04:14.5115840Z Test Suite 'Ably-iOS-Tests.xctest' failed at 2022-02-16 13:04:07.750.
2022-02-16T13:04:14.5115990Z 	 Executed 904 tests, with 2 failures (0 unexpected) in 751.031 (752.737) seconds
2022-02-16T13:04:14.5116210Z Test Suite 'All tests' failed at 2022-02-16 13:04:07.751.
2022-02-16T13:04:14.5116350Z 	 Executed 904 tests, with 2 failures (0 unexpected) in 751.031 (752.738) seconds
2022-02-16T13:04:14.5116710Z 2022-02-16 13:04:10.635 xcodebuild[60742:156405] [MT] IDETestOperationsObserverDebug: 770.132 elapsed -- Testing started completed.
2022-02-16T13:04:14.5117040Z 2022-02-16 13:04:10.635 xcodebuild[60742:156405] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2022-02-16T13:04:14.5117370Z 2022-02-16 13:04:10.635 xcodebuild[60742:156405] [MT] IDETestOperationsObserverDebug: 770.132 sec, +770.132 sec -- end
2022-02-16T13:04:14.5117440Z Failing tests:
2022-02-16T13:04:14.5117450Z 
2022-02-16T13:04:14.5117560Z Test session results, code coverage, and logs:
2022-02-16T13:04:14.5117890Z 	/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/test_output/sdk/test_iOS14_4/Ably-iOS-Tests.xcresult
2022-02-16T13:04:14.5117900Z 
2022-02-16T13:04:14.5118050Z 	Ably-iOS-Tests:
2022-02-16T13:04:14.5118280Z 		RealtimeClientConnectionTests.test__088__Connection__Host_Fallback__applies_when_the_default_realtime_ably_io_endpoint_is_being_used()
2022-02-16T13:04:14.5118540Z 		RealtimeClientConnectionTests.test__092__Connection__Host_Fallback__should_retry_hosts_in_random_order_after_checkin_if_an_internet_connection_is_available()
2022-02-16T13:04:14.5118550Z 
2022-02-16T13:04:14.5118620Z ** TEST FAILED **
2022-02-16T13:04:14.5118900Z ERROR [2022-02-16 13:04:14.28]: [31mExit status: 65[0m
2022-02-16T13:04:14.5119130Z DEBUG [2022-02-16 13:04:14.32]: Generating junit report with trainer
2022-02-16T13:04:14.5119140Z 
2022-02-16T13:04:14.5119480Z +------------------------------+--------------------------------------------------------------------------------+
2022-02-16T13:04:14.5119750Z |                                          [32mSummary for trainer 2.204.2[0m                                          |
2022-02-16T13:04:14.5120100Z +------------------------------+--------------------------------------------------------------------------------+
2022-02-16T13:04:14.5120410Z | path                         | fastlane/test_output/sdk/test_iOS14_4/Ably-iOS-Tests.xcresult                  |
2022-02-16T13:04:14.5120550Z | output_remove_retry_attempts | false                                                                          |
2022-02-16T13:04:14.5120670Z | silent                       | false                                                                          |
2022-02-16T13:04:14.5120790Z | output_filename              | report.junit                                                                   |
2022-02-16T13:04:14.5121100Z | output_directory             | /Users/runner/work/ably-cocoa/ably-cocoa/fastlane/test_output/sdk/test_iOS14_4 |
2022-02-16T13:04:14.5121430Z +------------------------------+--------------------------------------------------------------------------------+
2022-02-16T13:04:14.5121450Z 
2022-02-16T13:04:14.8569260Z INFO [2022-02-16 13:04:14.85]: [32mSuccessfully generated '/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/test_output/sdk/test_iOS14_4/report.junit'[0m
2022-02-16T13:04:14.8574990Z +--------------------+-----+
2022-02-16T13:04:14.8575320Z |       Test Results       |
2022-02-16T13:04:14.8575830Z +--------------------+-----+
2022-02-16T13:04:14.8576590Z | Number of tests    | 904 |
2022-02-16T13:04:14.8577070Z | Number of failures | [31m2[0m   |
2022-02-16T13:04:14.8577530Z +--------------------+-----+
2022-02-16T13:04:14.8577840Z 
2022-02-16T13:04:15.0591670Z WARN [2022-02-16 13:04:15.05]: [33m[33mLane Context:[0m
2022-02-16T13:04:15.0593570Z INFO [2022-02-16 13:04:15.05]: {:DEFAULT_PLATFORM=>:ios, :PLATFORM_NAME=>:ios, :LANE_NAME=>"ios test_iOS14_4", :SCAN_GENERATED_XCRESULT_PATH=>"/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/test_output/sdk/test_iOS14_4/Ably-iOS-Tests.xcresult", :SCAN_DERIVED_DATA_PATH=>"derived_data", :SCAN_GENERATED_PLIST_FILES=>[], :SCAN_GENERATED_PLIST_FILE=>nil}
2022-02-16T13:04:15.0595120Z ERROR [2022-02-16 13:04:15.05]: [31mTests have failed[0m
2022-02-16T13:04:15.0601760Z INFO [2022-02-16 13:04:15.05]: [32mSuccessfully generated documentation at path '/Users/runner/work/ably-cocoa/ably-cocoa/fastlane/README.md'[0m
2022-02-16T13:04:15.0615350Z 
2022-02-16T13:04:15.0625700Z +------+------------------+-------------+
2022-02-16T13:04:15.0626180Z |           [32mfastlane summary[0m            |
2022-02-16T13:04:15.0626500Z +------+------------------+-------------+
2022-02-16T13:04:15.0626720Z | Step | Action           | Time (in s) |
2022-02-16T13:04:15.0627030Z +------+------------------+-------------+
2022-02-16T13:04:15.0627240Z | 1    | default_platform | 0           |
2022-02-16T13:04:15.0627600Z | 💥   | [31mrun_tests[0m        | 788         |
2022-02-16T13:04:15.0627910Z +------+------------------+-------------+
2022-02-16T13:04:15.0628060Z 
2022-02-16T13:04:15.0628360Z ERROR [2022-02-16 13:04:15.06]: [31mfastlane finished with errors[0m
2022-02-16T13:04:15.0628980Z 
2022-02-16T13:04:15.0629720Z #######################################################################
2022-02-16T13:04:15.0630290Z # fastlane 2.204.3 is available. You are on 2.204.2.
2022-02-16T13:04:15.0630560Z # You should use the latest version.
2022-02-16T13:04:15.0630810Z # Please update using `bundle update fastlane`.
2022-02-16T13:04:15.0631130Z #######################################################################
2022-02-16T13:04:15.1352570Z 
2022-02-16T13:04:15.1353640Z [32m2.204.3 Improvements[0m
2022-02-16T13:04:15.1354280Z * [trainer][scan] identify skipped tests in `xcresult` and export to Junit format and output in scan (#19957) via Igor Makarov
2022-02-16T13:04:15.1354810Z * [Fastlane.Swift] Swift fastlane upgrader #18933 (#19914) via Enrique Garcia
2022-02-16T13:04:15.1355310Z * [pem][spaceship] update development push certificate type ID (#19879) via Igor Makarov
2022-02-16T13:04:15.1355830Z * [snapshot] fix compile error on macCatalyst (#19917) via Philipp Arndt
2022-02-16T13:04:15.1356320Z * [Fastlane.Swift] readPodspec: return map of [String: Any] (#19953) via Hais Deakin
2022-02-16T13:04:15.1356810Z * [match] update :force_for_new_certificates option description (#19938) via Wolfgang Lutz
2022-02-16T13:04:15.1358120Z 
2022-02-16T13:04:15.1358590Z [32mPlease update using `bundle update fastlane`[0m
2022-02-16T13:04:15.8347580Z bundler: failed to load command: fastlane (/usr/local/lib/ruby/gems/2.7.0/bin/fastlane)
2022-02-16T13:04:15.8367170Z /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/interface.rb:172:in `test_failure!': \e[31m[!] Tests have failed\e[0m (FastlaneCore::Interface::FastlaneTestFailure)
2022-02-16T13:04:15.8368320Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/ui.rb:17:in `method_missing'
2022-02-16T13:04:15.8369100Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:304:in `handle_results'
2022-02-16T13:04:15.8369820Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:24:in `run'
2022-02-16T13:04:15.8370500Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/manager.rb:23:in `work'
2022-02-16T13:04:15.8371200Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/run_tests.rb:17:in `run'
2022-02-16T13:04:15.8372450Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:263:in `block (2 levels) in execute_action'
2022-02-16T13:04:15.8373230Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/actions_helper.rb:69:in `execute_action'
2022-02-16T13:04:15.8374000Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:255:in `block in execute_action'
2022-02-16T13:04:15.8374720Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `chdir'
2022-02-16T13:04:15.8375690Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `execute_action'
2022-02-16T13:04:15.8376440Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:157:in `trigger_action_by_name'
2022-02-16T13:04:15.8377170Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/fast_file.rb:159:in `method_missing'
2022-02-16T13:04:15.8377700Z 	from Fastfile:16:in `block (2 levels) in parsing_binding'
2022-02-16T13:04:15.8378350Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane.rb:33:in `call'
2022-02-16T13:04:15.8379060Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:49:in `block in execute'
2022-02-16T13:04:15.8379760Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `chdir'
2022-02-16T13:04:15.8380480Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `execute'
2022-02-16T13:04:15.8381210Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane_manager.rb:47:in `cruise_lane'
2022-02-16T13:04:15.8381930Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/command_line_handler.rb:36:in `handle'
2022-02-16T13:04:15.8382710Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:109:in `block (2 levels) in run'
2022-02-16T13:04:15.8383440Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:187:in `call'
2022-02-16T13:04:15.8384140Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:157:in `run'
2022-02-16T13:04:15.8384830Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/runner.rb:444:in `run_active_command'
2022-02-16T13:04:15.8385580Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/fastlane_runner.rb:124:in `run!'
2022-02-16T13:04:15.8386310Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/delegates.rb:18:in `run!'
2022-02-16T13:04:15.8387030Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:353:in `run'
2022-02-16T13:04:15.8387750Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:42:in `start'
2022-02-16T13:04:15.8388510Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/cli_tools_distributor.rb:122:in `take_off'
2022-02-16T13:04:15.8389210Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/bin/fastlane:23:in `<top (required)>'
2022-02-16T13:04:15.8389710Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `load'
2022-02-16T13:04:15.8390150Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `<top (required)>'
2022-02-16T13:04:15.8390790Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli/exec.rb:58:in `load'
2022-02-16T13:04:15.8391470Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli/exec.rb:58:in `kernel_load'
2022-02-16T13:04:15.8392130Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli/exec.rb:23:in `run'
2022-02-16T13:04:15.8392790Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli.rb:484:in `exec'
2022-02-16T13:04:15.8393830Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor/command.rb:27:in `run'
2022-02-16T13:04:15.8394580Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor/invocation.rb:127:in `invoke_command'
2022-02-16T13:04:15.8395320Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor.rb:392:in `dispatch'
2022-02-16T13:04:15.8396090Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli.rb:31:in `dispatch'
2022-02-16T13:04:15.8397000Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor/base.rb:485:in `start'
2022-02-16T13:04:15.8397670Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli.rb:25:in `start'
2022-02-16T13:04:15.8398350Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/exe/bundle:48:in `block in <top (required)>'
2022-02-16T13:04:15.8399080Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/friendly_errors.rb:103:in `with_friendly_errors'
2022-02-16T13:04:15.8399780Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/exe/bundle:36:in `<top (required)>'
2022-02-16T13:04:15.8400260Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `load'
2022-02-16T13:04:15.8400690Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `<main>'
2022-02-16T13:04:15.8401660Z /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/interface.rb:172:in `test_failure!': Tests have failed (FastlaneCore::Interface::FastlaneTestFailure)
2022-02-16T13:04:15.8402490Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/ui.rb:17:in `method_missing'
2022-02-16T13:04:15.8403220Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:304:in `handle_results'
2022-02-16T13:04:15.8403900Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/runner.rb:24:in `run'
2022-02-16T13:04:15.8404580Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/scan/lib/scan/manager.rb:23:in `work'
2022-02-16T13:04:15.8405290Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/run_tests.rb:17:in `run'
2022-02-16T13:04:15.8406050Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:263:in `block (2 levels) in execute_action'
2022-02-16T13:04:15.8406820Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/actions/actions_helper.rb:69:in `execute_action'
2022-02-16T13:04:15.8407600Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:255:in `block in execute_action'
2022-02-16T13:04:15.8408310Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `chdir'
2022-02-16T13:04:15.8409020Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:229:in `execute_action'
2022-02-16T13:04:15.8409760Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:157:in `trigger_action_by_name'
2022-02-16T13:04:15.8410490Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/fast_file.rb:159:in `method_missing'
2022-02-16T13:04:15.8411010Z 	from Fastfile:16:in `block (2 levels) in parsing_binding'
2022-02-16T13:04:15.8411650Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane.rb:33:in `call'
2022-02-16T13:04:15.8412380Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:49:in `block in execute'
2022-02-16T13:04:15.8413080Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `chdir'
2022-02-16T13:04:15.8413790Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/runner.rb:45:in `execute'
2022-02-16T13:04:15.8414510Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/lane_manager.rb:47:in `cruise_lane'
2022-02-16T13:04:15.8415490Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/command_line_handler.rb:36:in `handle'
2022-02-16T13:04:15.8417510Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:109:in `block (2 levels) in run'
2022-02-16T13:04:15.8418550Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:187:in `call'
2022-02-16T13:04:15.8419250Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/command.rb:157:in `run'
2022-02-16T13:04:15.8420200Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/runner.rb:444:in `run_active_command'
2022-02-16T13:04:15.8420960Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane_core/lib/fastlane_core/ui/fastlane_runner.rb:124:in `run!'
2022-02-16T13:04:15.8421690Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/commander-4.6.0/lib/commander/delegates.rb:18:in `run!'
2022-02-16T13:04:15.8422410Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:353:in `run'
2022-02-16T13:04:15.8423150Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/commands_generator.rb:42:in `start'
2022-02-16T13:04:15.8423900Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/fastlane/lib/fastlane/cli_tools_distributor.rb:122:in `take_off'
2022-02-16T13:04:15.8424700Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/fastlane-2.204.2/bin/fastlane:23:in `<top (required)>'
2022-02-16T13:04:15.8425200Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `load'
2022-02-16T13:04:15.8425660Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/fastlane:25:in `<top (required)>'
2022-02-16T13:04:15.8426290Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli/exec.rb:58:in `load'
2022-02-16T13:04:15.8426980Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli/exec.rb:58:in `kernel_load'
2022-02-16T13:04:15.8427630Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli/exec.rb:23:in `run'
2022-02-16T13:04:15.8428300Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli.rb:484:in `exec'
2022-02-16T13:04:15.8429010Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor/command.rb:27:in `run'
2022-02-16T13:04:15.8429740Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor/invocation.rb:127:in `invoke_command'
2022-02-16T13:04:15.8430480Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor.rb:392:in `dispatch'
2022-02-16T13:04:15.8431170Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli.rb:31:in `dispatch'
2022-02-16T13:04:15.8431870Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/vendor/thor/lib/thor/base.rb:485:in `start'
2022-02-16T13:04:15.8432530Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/cli.rb:25:in `start'
2022-02-16T13:04:15.8433220Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/exe/bundle:48:in `block in <top (required)>'
2022-02-16T13:04:15.8433930Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/lib/bundler/friendly_errors.rb:103:in `with_friendly_errors'
2022-02-16T13:04:15.8434620Z 	from /usr/local/lib/ruby/gems/2.7.0/gems/bundler-2.3.6/exe/bundle:36:in `<top (required)>'
2022-02-16T13:04:15.8435090Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `load'
2022-02-16T13:04:15.8435520Z 	from /usr/local/lib/ruby/gems/2.7.0/bin/bundle:23:in `<main>'
```

## Results

- [First attempt at looping](https://github.com/ably/ably-cocoa/runs/5156594828?check_suite_focus=true)
- I'm not 100% sure I trust the JUnit results (looking at the end of the test run in the loop the tests just seem to abruptly end without the Xcode failure summary…)
- I wish we had the .xcresult files too, for later reference. Especially in the loop ones.
