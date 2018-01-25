#!/bin/bash

# exit if a command fails
set -e

cd "Examples/Tests"
pod install
fastlane scan -s Tests
