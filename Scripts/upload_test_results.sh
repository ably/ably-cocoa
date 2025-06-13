#!/bin/bash

# Uploads a test results file from fastlane/test_output/sdk/**/*.xcresult to the test observability server.
# Must be run from root of repo.

# Options:
# -u / --upload-server-base-url <url>: Allows you to specify a URL to use as the upload server base URL. Defaults to https://test-observability.herokuapp.com.
# -i / --iteration <number>: If running the tests in a loop inside a single CI job, indicates which iteration of the loop is currently executing. Defaults to 1.
# -j / --job-name <name> (optional): The `name` property of the object corresponding to the current job in the response from the "list jobs for a workflow run attempt" GitHub API (https://docs.github.com/en/rest/actions/workflow-jobs?apiVersion=2022-11-28#list-jobs-for-a-workflow-run-attempt). If there is more than one object in the response whose `name` property equals this value, the action will fail. If you specify `GITHUB_TOKEN` but not `--job-name`, and the response from this API contains more than one job, the script will fail.
#
# Optional environment variables:
#
# GITHUB_TOKEN: A GitHub access token. If provided, the script will perform a GitHub API call in order to discover the web URL for the current job, and will include this URL in the observability server upload.

set -e

# 1. Check dependencies.

if ! which jq > /dev/null
then
  echo "You need to install jq." 2>&1
  exit 1
fi

if ! which gh > /dev/null
then
  echo "You need to install the GitHub CLI." 2>&1
  exit 1
fi

if [[ ! -d xcparse ]]
then
  echo "You need to check out the xcparse repository." 2>&1
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
        -j|--job-name) job_name="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z $iteration ]]
then
  iteration=1
fi

# 4. Find the .xcresult bundle.

# We use ~+ to give us an absolute path (https://askubuntu.com/a/1033450)
result_bundles=$(find ~+/fastlane/test_output/sdk -name '*.xcresult')
if [[ -z $result_bundles ]]
then
  number_of_result_bundles=0
else
  number_of_result_bundles=$(echo "${result_bundles}" | wc -l)
fi

if [[ $number_of_result_bundles -eq 0 ]]
then
  echo "No result bundles found." 2>&1
  exit 1
fi

if [[ $number_of_result_bundles -gt 1 ]]
then
  echo -e "Multiple result bundles found:\n${result_bundles}" 2>&1
  exit 1
fi

echo "Result bundle found: ${result_bundles}" 2>&1

# 5. Generate the JUnit test report.
junit_report_directory=$(dirname "${result_bundles}")

# Recent versions of fastlane have started generating JUnit reports with nested <testsuite> tags; the test-observability server does not know how to handle these and I'm not sure that they're allowed. Have raised https://github.com/fastlane/fastlane/issues/29615. In the meantime, to avoid this issue, we need to use trainer's :force_legacy_xcresulttool option.

# Delete the JUnit report that `scan` generated; we need to re-generate it by running `trainer` again, this time with the :force_legacy_xcresulttool option (which according to https://github.com/fastlane/fastlane/issues/29614 you can't pass directly to `scan`).
echo "Deleting existing JUnit reports." 2>&1
find "${junit_report_directory}" -type f -name '*.junit' -delete

echo "Generating new JUnit report." 2>&1
# I can't get `trainer`'s output_filename option to work; it just seems to choose its own name. Hence the next step where we have to find the generated file.
bundle exec fastlane run trainer \
    force_legacy_xcresulttool:true \
    extension:".junit" \
    fail_build:false \
    path:"${junit_report_directory}" \

# 6. Find the JUnit test report.

test_reports=$(find "${junit_report_directory}" -name '*.junit')
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

# 7. Use xcparse to extract the crash reports from the .xcresult bundle.

xcparse_output_directory=$(mktemp -d)
echo "Extracting result bundle attachments to ${xcparse_output_directory}." 2>&1

cd xcparse
if [[ ! -f .build/debug/xcparse ]]
then
  swift build
fi

.build/debug/xcparse attachments "${result_bundles}" "${xcparse_output_directory}"
cd ..

xcparse_attachment_descriptors_file="${xcparse_output_directory}/xcparseAttachmentDescriptors.json"

# 8. Filter the output of xcparse to find just the crash reports (files whose name ends in .crash or .ips).

filtered_xcparse_attachment_descriptors_file=$(mktemp)

jq 'map(select(.attachmentName | (endswith(".crash") or endswith(".ips"))))' < "${xcparse_attachment_descriptors_file}" > "${filtered_xcparse_attachment_descriptors_file}"

declare -i number_of_filtered_attachments
number_of_filtered_attachments=$(jq '. | length' < "${filtered_xcparse_attachment_descriptors_file}")

echo "There is/are ${number_of_filtered_attachments} crash report(s) in total." 2>&1

crash_reports_json_file=$(mktemp)
echo '[]' > $crash_reports_json_file

for ((i=0; i < ${number_of_filtered_attachments}; i+=1))
do
  attachment_file="${xcparse_output_directory}/$(jq --raw-output ".[${i}].attachmentName" < "${filtered_xcparse_attachment_descriptors_file}")"

  temp_crash_reports_json_file=$(mktemp)
  jq \
    --slurpfile attachmentDescriptors "${filtered_xcparse_attachment_descriptors_file}" \
    --rawfile attachment "${attachment_file}" \
    ". += [{filename: \$attachmentDescriptors[0][$i].attachmentName, test_class_name: \$attachmentDescriptors[0][$i].testClassName, test_case_name: \$attachmentDescriptors[0][$i].testCaseName, data: \$attachment | @base64 }]" \
    < "${crash_reports_json_file}" \
    > "${temp_crash_reports_json_file}"

  crash_reports_json_file="${temp_crash_reports_json_file}"
done

# 9. Fetch the details of the current GitHub job, so that we can add a link to it in the upload.
#
# It’s a bit surprising that there’s no built-in functionality for this (see e.g. https://stackoverflow.com/questions/71240338/obtain-job-id-from-a-workflow-run-using-contexts or https://github.com/orgs/community/discussions/8945).

if [[ ! -z $GITHUB_TOKEN ]]
then
  temp_github_jobs_response_file=$(mktemp)
  gh api "/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/attempts/${GITHUB_RUN_ATTEMPT}/jobs" > $temp_github_jobs_response_file

  matching_jobs_file=$(mktemp)

  if [[ -z $job_name ]]
  then
    number_of_jobs=$(jq '.jobs | length' < "${temp_github_jobs_response_file}")

    if [[ $number_of_jobs -eq 0 ]]
    then
      echo -e "Got no jobs from GitHub API." 2>&1
      exit 1
    fi

    if [[ $number_of_jobs -gt 1 ]]
    then
      echo -e "Got ${number_of_jobs} jobs from GitHub API but don’t know which one to pick. You need to provide a --job-name argument." 2>&1
      exit 1
    fi

    jq '.jobs' < "${temp_github_jobs_response_file}" > "${matching_jobs_file}"
  else
    jq --arg job_name "${job_name}" '.jobs | map(select(.name == $job_name))' < "${temp_github_jobs_response_file}" > "${matching_jobs_file}"

    number_of_matching_jobs=$(jq '. | length' < "${matching_jobs_file}")

    if [[ $number_of_matching_jobs -eq 0 ]]
    then
      echo -e "The GitHub API response contains no job whose \`name\` is ${job_name}. This script does not currently handle pagination." 2>&1
      exit 1
    fi

    if [[ $number_of_matching_jobs -gt 1 ]]
    then
      echo -e "The GitHub API response contains multiple jobs whose \`name\` is ${job_name}." 2>&1
      exit 1
    fi
  fi

  github_job_api_url=$(jq --exit-status --raw-output ".[0].url" < "${matching_jobs_file}")
  github_job_html_url=$(jq --exit-status --raw-output ".[0].html_url" < "${matching_jobs_file}")
fi

# 10. Create the JSON request body.

temp_request_body_file=$(mktemp)

# https://unix.stackexchange.com/questions/446847/conditionally-pass-params-to-a-script
optional_params=()

if [[ ! -z $GITHUB_BASE_REF ]]
then
  optional_params+=(--arg github_base_ref "${GITHUB_BASE_REF}")
else
  optional_params+=(--argjson github_base_ref null)
fi

if [[ ! -z $GITHUB_HEAD_REF ]]
then
  optional_params+=(--arg github_head_ref "${GITHUB_HEAD_REF}")
else
  optional_params+=(--argjson github_head_ref null)
fi

if [[ ! -z $github_job_api_url ]]
then
  optional_params+=(--arg github_job_api_url "${github_job_api_url}")
else
  optional_params+=(--argjson github_job_api_url null)
fi

if [[ ! -z $github_job_html_url ]]
then
  optional_params+=(--arg github_job_html_url "${github_job_html_url}")
else
  optional_params+=(--argjson github_job_html_url null)
fi

jq -n \
  --rawfile junit_report_xml "${test_reports}" \
  --slurpfile crash_reports "${crash_reports_json_file}" \
  --arg github_repository "${GITHUB_REPOSITORY}" \
  --arg github_sha "${GITHUB_SHA}" \
  --arg github_ref_name "${GITHUB_REF_NAME}" \
  --arg github_retention_days "${GITHUB_RETENTION_DAYS}" \
  --arg github_action "${GITHUB_ACTION}" \
  --arg github_run_number "${GITHUB_RUN_NUMBER}" \
  --arg github_run_attempt "${GITHUB_RUN_ATTEMPT}" \
  --arg github_run_id "${GITHUB_RUN_ID}" \
  --arg github_job "${GITHUB_JOB}" \
  --arg iteration "${iteration}" \
  "${optional_params[@]}" \
  '{ junit_report_xml: $junit_report_xml | @base64, crash_reports: $crash_reports[0], github_repository: $github_repository, github_sha: $github_sha, github_ref_name: $github_ref_name, github_retention_days: $github_retention_days, github_action: $github_action, github_run_number: $github_run_number, github_run_attempt: $github_run_attempt, github_run_id: $github_run_id, github_base_ref: $github_base_ref, github_head_ref: $github_head_ref, github_job: $github_job, github_job_api_url: $github_job_api_url, github_job_html_url: $github_job_html_url, iteration: $iteration }' \
  > "${temp_request_body_file}"

# I've turned off logging of the response body because it adds about 2 minutes to the GitHub job execution time. I suspect it might be related to https://github.com/actions/runner/issues/1031 ("Long log lines slow down the runner"). Set the below `false` to `true` if you want to temporarily turn this logging back on.
if false
then
  echo "::group::Request body"
  printf "Created request body:\n$(cat "${temp_request_body_file}")\n\n" 2>&1
  echo "::endgroup::"
fi

# 11. Send the request.

echo "Uploading test report." 2>&1

if [[ -z $upload_server_base_url ]]
then
  upload_server_base_url="https://test-observability.herokuapp.com"
fi

request_id=$(uuidgen)

temp_response_body_file=$(mktemp)
curl -vv --fail-with-body --data-binary "@${temp_request_body_file}" --header "Content-Type: application/json" --header "Test-Observability-Auth-Key: ${TEST_OBSERVABILITY_SERVER_AUTH_KEY}" --header "X-Request-ID: ${request_id}" "${upload_server_base_url}/uploads" | tee "${temp_response_body_file}"
echo 2>&1 # Print a newline to separate the `curl` output from the next log line.

# 12. Extract the ID of the created upload and log the web UI URL.

upload_id=$(jq --exit-status --raw-output '.id' < "${temp_response_body_file}")
web_ui_url="${upload_server_base_url}/repos/${GITHUB_REPOSITORY}/uploads/${upload_id}"
echo "Test results uploaded successfully: ${web_ui_url}"
