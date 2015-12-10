#!/bin/bash

set -o pipefail

: ${BUILDTOOL:=xcodebuild} #Default
: ${CLASS:=""} #Default: test all classes (only works on xctool)

# Xcode Build Command Line
# https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html
: ${WORKSPACE:="ably.xcworkspace"}
: ${SCHEME:="ably"}
: ${CONFIGURATION:="Release"}
: ${SDK:="iphonesimulator9.1"}
: ${DESTINATION:="platform=iOS Simulator,OS=8.4,name=iPhone 4s"}

init() {
  # Launch the simulator before running the tests
  # Avoid "iPhoneSimulator: Timed out waiting"
  open -b com.apple.iphonesimulator
}

COMMAND="-workspace \"${WORKSPACE}\" -scheme \"${SCHEME}\" -configuration \"${CONFIGURATION}\" -sdk \"${SDK}\" -destination \"${DESTINATION}\" ONLY_ACTIVE_ARCH=NO"

case "${BUILDTOOL}" in
  xctool) echo "Selected build tool: xctool"
  init
    # Tests (Swift & Objective-C)
  	case "${CLASS}" in
  	  "") echo "Testing all classes"
      COMMAND="xctool clean test "${COMMAND}
      ;;
      *) echo "Testing ${CLASS}"
      COMMAND="xctool clean test -only ${CLASS} "${COMMAND}
      ;;
  	esac
  ;;
  xcodebuild-travis) echo "Selected tool: xcodebuild + xcpretty (format: travisci)"
  init
    # Use xcpretty together with tee to store the raw log in a file, and get the pretty output in the terminal
    xcodebuild clean test -workspace "${WORKSPACE}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" -sdk "${SDK}" -destination "${DESTINATION}" ONLY_ACTIVE_ARCH=NO | tee xcodebuild.log | xcpretty -f `xcpretty-travis-formatter`
  ;;
  xcodebuild-pretty) echo "Selected tool: xcodebuild + xcpretty"
  init
    xcodebuild clean test -workspace "${WORKSPACE}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" -sdk "${SDK}" -destination "${DESTINATION}" ONLY_ACTIVE_ARCH=NO | tee xcodebuild.log | xcpretty --test
  ;;
  xcodebuild) echo "Selected tool: xcodebuild"
  init
    xcodebuild clean test -workspace "${WORKSPACE}" -scheme "${SCHEME}" -configuration "${CONFIGURATION}" -sdk "${SDK}" -destination "${DESTINATION}" ONLY_ACTIVE_ARCH=NO
  ;;
  *) echo "No build tool especified" && exit 2
esac

set -x
eval "${COMMAND}"