#!/bin/bash

# exit if a command fails
set -e

# Facebook Replacement for Apple's xcodebuild
brew update && brew install xctool

# Xcode Build formatter
gem install xcpretty

# Custom formatter for xcpretty with some syntactic sugar for presentation on TravisCI
# https://github.com/kattrali/xcpretty-travis-formatter
gem install xcpretty-travis-formatter --no-rdoc --no-ri --no-document --quiet

# Install CocoaPods
gem install cocoapods -v '0.39.0'