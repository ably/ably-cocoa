#!/bin/bash

# Uploads a test results file from fastlane/test_output/sdk/**/*.junit to the test observability server.
# Must be run from root of repo.

# Options:
# -u / --upload-server-base-url <url>: Allows you to specify a URL to use as the upload server base URL. Defaults to https://test-observability.herokuapp.com.
# -i / --iteration <number>: If running the tests in a loop inside a single CI job, indicates which iteration of the loop is currently executing. Defaults to 1.

set -e

# 1. Check dependencies.

if ! which jq > /dev/null
then
  echo "You need to install jq." 2>&1
  exit 1
fi

# 2. Grab the variables from the environment.

if [[ -z $TEST_OBSERVABILITY_SERVER_AUTH_KEY ]]
then
  echo "The TEST_OBSERVABILITY_SERVER_AUTH_KEY environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_REPOSITORY ]]
then
  echo "The GITHUB_REPOSITORY environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_SHA ]]
then
  echo "The GITHUB_SHA environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_REF_NAME ]]
then
  echo "The GITHUB_REF_NAME environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_RETENTION_DAYS ]]
then
  echo "The GITHUB_RETENTION_DAYS environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_ACTION ]]
then
  echo "The GITHUB_ACTION environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_RUN_NUMBER ]]
then
  echo "The GITHUB_RUN_NUMBER environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_RUN_ATTEMPT ]]
then
  echo "The GITHUB_RUN_ATTEMPT environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_RUN_ID ]]
then
  echo "The GITHUB_RUN_ID environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_BASE_REF ]]
then
  echo "The GITHUB_BASE_REF environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_HEAD_REF ]]
then
  echo "The GITHUB_HEAD_REF environment variable must be set." 2>&1
  exit 1
fi

if [[ -z $GITHUB_JOB ]]
then
  echo "The GITHUB_JOB environment variable must be set." 2>&1
  exit 1
fi

# 3. Grab command-line options.

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--iteration) iteration="$2"; shift ;;
        -u|--upload-server-base-url) upload_server_base_url="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z $iteration ]]
then
  iteration=1
fi

# 4. Find the JUnit test report.

test_reports=$(find fastlane/test_output/sdk -name '*.junit')
if [[ -z $test_reports ]]
then
  number_of_test_reports=0
else
  number_of_test_reports=$(echo "${test_reports}" | wc -l)
fi

if [[ $number_of_test_reports -eq 0 ]]
then
  echo "No test reports found." 2>&1
  exit 1
fi

if [[ $number_of_test_reports -gt 1 ]]
then
  echo -e "Multiple test reports found:\n${test_reports}" 2>&1
  exit 1
fi

echo "Test report found: ${test_reports}" 2>&1

# 4. Create the JSON request body.

temp_request_body_file=$(mktemp)

jq -n \
  --rawfile junit_report_xml "${test_reports}" \
  --arg github_repository "${GITHUB_REPOSITORY}" \
  --arg github_sha "${GITHUB_SHA}" \
  --arg github_ref_name "${GITHUB_REF_NAME}" \
  --arg github_retention_days "${GITHUB_RETENTION_DAYS}" \
  --arg github_action "${GITHUB_ACTION}" \
  --arg github_run_number "${GITHUB_RUN_NUMBER}" \
  --arg github_run_attempt "${GITHUB_RUN_ATTEMPT}" \
  --arg github_run_id "${GITHUB_RUN_ID}" \
  --arg github_base_ref "${GITHUB_BASE_REF}" \
  --arg github_head_ref "${GITHUB_HEAD_REF}" \
  --arg github_job "${GITHUB_JOB}" \
  --arg iteration "${iteration}" \
  '{ junit_report_xml: $junit_report_xml | @base64, github_repository: $github_repository, github_sha: $github_sha, github_ref_name: $github_ref_name, github_retention_days: $github_retention_days, github_action: $github_action, github_run_number: $github_run_number, github_run_attempt: $github_run_attempt, github_run_id: $github_run_id, github_base_ref: $github_base_ref, github_head_ref: $github_head_ref, github_job: $github_job, iteration: $iteration }' \
  > "${temp_request_body_file}"

# 5. Send the request.

echo "Uploading test report." 2>&1

if [[ -z $upload_server_base_url ]]
then
  upload_server_base_url="https://test-observability.herokuapp.com"
fi

curl -vvv --fail --data-binary "@${temp_request_body_file}" --header "Content-Type: application/json" --header "Test-Observability-Auth-Key: ${TEST_OBSERVABILITY_SERVER_AUTH_KEY}" "${upload_server_base_url}/uploads"
