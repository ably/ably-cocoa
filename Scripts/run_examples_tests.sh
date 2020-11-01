#!/bin/bash

# exit if a command fails
set -e

# This is the script specified as the pod’s prepare_command in its Podspec.
# It would be run automatically for a normal CocoaPods install, but it doesn’t
# get run when the dependency is specified with the :path option. So we run it
# manually.
Scripts/prepare-pod.sh

cd "Examples/Tests"
pod repo update
pod install
bundle exec fastlane scan -s Tests
