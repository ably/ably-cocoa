#!/bin/bash

# exit if a command fails
set -e

# Install Fastlane
gem install fastlane -v 2.77.1

# Install CocoaPods
gem install cocoapods

# Install Carthage
brew update && brew install carthage

# Install dependencies
pod install
carthage bootstrap
