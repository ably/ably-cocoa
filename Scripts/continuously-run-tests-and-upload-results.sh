#!/bin/bash

set -e

# 1. Check dependencies.

if ! which timeout > /dev/null
then
  echo "You need to install timeout (\`brew install coreutils\` on macOS)." 2>&1
  exit 1
fi

# 2. Find out which Fastlane lane we’re running.

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

# 3. Capture the time at which we started, to make sure we don’t exceed the
# maximum job running time.
started_at=`date +%s`
# https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration
let github_job_maximum_execution_seconds=6*60*60
# We assume that the part of the job that ran before this script took at most 10 minutes, and that uploading the artifacts will take 10 minutes.
let must_end_by=$((started_at + github_job_maximum_execution_seconds - (10 + 10) * 60))

echo "We’ll make sure this script ends by `date -r${must_end_by}`." 2>&1

# 4. Run the tests in a loop and report the results.

declare -i iteration=1
while true
do
  echo "BEGIN ITERATION ${iteration}" 2>&1

  rm -rf fastlane/test_output
  rm -rf xcodebuild_output
  xcrun simctl erase all

  let allowed_execution_time=$must_end_by-`date +%s`

  echo "ITERATION ${iteration}: Running fastlane with a timeout of ${allowed_execution_time} seconds." 2>&1

  set +e
  timeout --kill-after=20 ${allowed_execution_time} bundle exec fastlane --verbose $lane
  tests_exit_value=$?
  set -e

  if [[ tests_exit_value -eq 124 || tests_exit_value -eq 137 ]]; then
    # Execution timed out.
    echo "ITERATION ${iteration}: Cancelled the execution of fastlane since it exceeded timeout imposed by maximum GitHub running time. Terminating this script."
    echo "There are `du -d0 -h xcresult-bundles | awk -F '\t' '{print $1}'` of xcresult bundles to be uploaded."
    exit 0
  fi

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
