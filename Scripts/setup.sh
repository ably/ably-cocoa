#!/bin/bash

# exit if a command fails
set -e

# Facebook Replacement for Apple's xcodebuild
brew update && brew install xctool

# Install Scan
gem install scan

# Install CocoaPods
gem install cocoapods -v '0.39.0'