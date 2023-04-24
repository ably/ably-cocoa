#!/bin/bash

set -e

# 1. Find out which Fastlane lane we’re running.

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -l|--lane) lane="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z $lane ]]
then
  echo "You need to specify the Fastlane lane to run (-l / --lane)." 2>&1
  exit 1
fi

# 2. Run the tests in a loop and report the results.

declare -i iteration=1
while true
do
  echo "BEGIN ITERATION ${iteration}" 2>&1

  rm -rf fastlane/test_output
  rm -rf xcodebuild_output
  xcrun simctl erase all

  set +e
  bundle exec fastlane --verbose $lane
  tests_exit_value=$?
  set -e

  if [[ tests_exit_value -eq 0 ]]
  then
    echo "ITERATION ${iteration}: Tests passed."
  else
    echo "ITERATION ${iteration}: Tests failed (exit value ${tests_exit_value})."
  fi

  echo "ITERATION ${iteration}: BEGIN xcodebuild raw output."
  ls xcodebuild_output
  cat xcodebuild_output/**
  echo "ITERATION ${iteration}: END xcodebuild raw output."

  echo "ITERATION ${iteration}: Uploading results to observability server."
  ./Scripts/upload_test_results.sh --iteration $iteration

  # Find the .xcresult bundle and copy it to the directory that will eventually be saved as an artifact.

  result_bundles=$(find fastlane/test_output/sdk -name '*.xcresult')
  if [[ -z $result_bundles ]]
  then
    number_of_result_bundles=0
  else
    number_of_result_bundles=$(echo "${result_bundles}" | wc -l)
  fi

  if [[ $number_of_result_bundles -eq 0 ]]
  then
    echo "ITERATION ${iteration}: No result bundles found."
    exit 1
  fi

  if [[ $number_of_result_bundles -gt 1 ]]
  then
    echo -e "ITERATION ${iteration}: Multiple result bundles found:\n${result_bundles}"
    exit 1
  fi

  echo "ITERATION ${iteration}: Report bundle found: ${result_bundles}"

  if [[ ! -d xcresult-bundles ]]; then
    mkdir xcresult-bundles
  fi

  mkdir "xcresult-bundles/${iteration}"
  cp -r "${result_bundles}" "xcresult-bundles/${iteration}"

  echo "ITERATION ${iteration}: Copied result bundle to xcresult-bundles/${iteration}."

  echo "END ITERATION ${iteration}" 2>&1

  iteration+=1
done
