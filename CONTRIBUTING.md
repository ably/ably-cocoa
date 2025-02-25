# Contributing

In this repository the `main` branch contains the latest development version of the Ably SDK. All development (bug fixing, feature implementation, etc.) is done against the `main` branch, which you should branch from whenever you'd like to make modifications. Here's the steps to follow when contributing to this repository.

 - Fork it
 - Install Carthage: `brew install carthage`
 - Install gems: `bundle install`
 - Setup or update your machine by running `make update`
 - Create your feature branch from `main` (`git checkout main && git checkout -b my-new-feature-branch`)
 - Commit your changes (`git commit -am 'Add some feature'`)
 - Ensure you have added suitable tests and the test suite is passing
 - Push to the branch (`git push origin my-new-feature-branch`)
 - Create a new Pull Request

Releases of the Ably SDK built by the sources in this repository are tagged with their [semantic version](http://semver.org/) numbers.

## Development Flow

When you first clone the repository then you will need to run `make update` in order to
bring in Git submodules and Carthage dependencies.

Code can then be modified, built and tested by loading [Ably.xcodeproj](Ably.xcodeproj) in your Xcode IDE.

The Xcode project relies upon dependencies resolved by Carthage.
If you make changes to the [Cartfile](Cartfile) then you will need to run `make update_carthage_dependencies`
from the command line and then do a clean rebuild in Xcode.

Changes made to dependencies in the [Cartfile](Cartfile) need to be reflected in
[Ably.podspec](Ably.podspec) and vice-versa.

## Adding new Objective-C files to the SDK

### Public header (`.h`) files

These are the header files that form the public interface of the SDK.

1. Put `.h` file in directory `Source/include/Ably`.
1. Add `#import` to one of the following umbrella header files:
   - `Source/include/Ably/AblyPublic.h` if the API contained in this header is intended for general use.
   - `Source/include/Ably/AblyInternal.h` if the API contained in this header is intended for use only by Ably-authored SDKs and should not be included in the Jazzy-generated documentation.
1. Add to the Xcode project `Ably.xcodeproj` — you need to add it as a Public header to all three SDK targets (Ably-iOS, Ably-macOS, Ably-tvOS).

### Private header (`.h`) files

These are the header files that form the internal interface of the SDK.

1. Put `.h` file in directory `Source/PrivateHeaders/Ably`.
1. Add `header` declaration to the `Private` module in module map file `Source/Ably.modulemap`.
1. Add to the Xcode project `Ably.xcodeproj` — you need to add it as a Private header to all three SDK targets (Ably-iOS, Ably-macOS, Ably-tvOS).

### Implementation (`.m`) files

1. Put `.m` file in directory `Source`.
1. Add to the Xcode project `Ably.xcodeproj` — you need to add it to all three SDK targets (Ably-iOS, Ably-macOS, Ably-tvOS).

## Running tests

To run tests use `make test_[iOS|tvOS|macOS]`. These tests expect you to have a simulator device of a specific model and OS version. See [`Fastfile`](./fastlane/Fastfile) for these values. If you don’t have a matching simulator, you can create one using `simctl`. For example, `xcrun simctl create "iPhone 12 (14.4)" "iPhone 12" "com.apple.CoreSimulator.SimRuntime.iOS-14-4"`.

## Release Process

For each release, the following needs to be done:

* Create a new branch `release/x.x.x` (where `x.x.x` is the new version number) from the `main` branch
* Run `make bump_[major|minor|patch]` to bump the new version number. This will create a Git commit, push it to origin: `git push -u origin release/x.x.x`
* Go to [Github releases](https://github.com/ably/ably-cocoa/releases) and press the `Draft a new release` button. Choose your new branch as a target
* Press the `Choose a tag` dropdown and start typing a new tag, Github will suggest the `Create new tag x.x.x on publish` option. After you select it Github will unveil the `Generate release notes` button
* From the newly generated changes remove everything that don't make much sense to the library user
* Copy the final list of changes to the top of the `CHANGELOG.md` file. Modify as necessary to fit the existing format of this file
* Commit these changes and push to the origin `git add CHANGELOG.md && git commit -m "Update change log." && git push -u origin release/x.x.x`
* Make a pull request against `main` and await approval of reviewer(s)
* Once approved and/or any additional commits have been added, merge the PR (f you do this from Github's web interface then use the "Rebase and merge" option)
* After merging the PR, wait for all CI jobs for `main` to pass.
* If any fixes are needed (e.g. the lint fails with warnings) then either commit them to the `main` branch now (don't forget to pull the changes first `git checkout main && git pull`) if they are simple warning fixes or perhaps consider raising a new PR if they are complex or likely need a review.
* Publish your drafted release:
    * refer to previous releases for release notes format
    * attach to the release the prebuilt framework file (`Ably.framework.zip`) generated by Carthage – you can find this file in the `carthage-built-framework` artifact uploaded by the `check-pod` CI workflow
* Checkout `main` locally, pulling in changes using `git checkout main && git pull`. Make sure the new tag you need was created on publish
* Release an update for CocoaPods using `pod trunk push Ably.podspec`. Details on this command, as well as instructions for adding other contributors as maintainers, are at [Getting setup with Trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk.html) in the [CocoaPods Guides](https://guides.cocoapods.org/)
* Test the integration of the library in a Xcode project using Carthage and CocoaPods using the [installation guide](https://github.com/ably/ably-cocoa#installation-guide)
