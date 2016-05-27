#!/bin/bash

# exit if a command fails
set -e

cd "Examples/Tests"
pod install
scan -s Tests
