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

And then just set it up running in a loop in a CI job (up to 72 hours)

## How might I analyse this sort of thing?

Is a time-series DB like InfluxDB / Prometheus (with a dashboard like e.g. Grafana) appropriate? I know little about this sort of thing. I don't think that ElasticSearch has anything to do with what I want.

**Probably would help if I knew what sort of querying I wanted to do.**

[A metrics suite for JUnit test code: a multiple case study on open source software](https://jserd.springeropen.com/articles/10.1186/s40411-014-0014-6) - no idea if this has anything to do with what I’m looking at
