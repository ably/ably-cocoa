#!/bin/bash

set -e

# 1. Grab command-line options.

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -l|--lane) lane="$2"; shift ;;
        -u|--upload-server-base-url) upload_server_base_url="$2"; shift ;;
        -j|--job-index) job_index="$2"; shift ;;
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

  # https://unix.stackexchange.com/questions/446847/conditionally-pass-params-to-a-script
  optional_params=()

  if [[ ! -z $upload_server_base_url ]]
  then
    optional_params+=(--upload-server-base-url "${upload_server_base_url}")
  fi

  if [[ ! -z $job_index ]]
  then
    optional_params+=(--job-index "${job_index}")
  fi

  ./Scripts/upload_test_results.sh \
    --iteration $iteration \
    "${optional_params[@]}"

  echo "END ITERATION ${iteration}" 2>&1

  iteration+=1
done
