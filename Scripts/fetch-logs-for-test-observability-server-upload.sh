# Given the ID of a upload on the test observability server, retrieves the raw xcodebuild output for that test run. Only works for tests that were run in a loop.

# Usage:
# ./fetch-logs-for-test-observability-server-upload.sh \
#   --upload-id <id> 

# Options:
# -i / --upload-id <id>: The ID of a upload saved on the test observability server.
# -u / --upload-server-base-url <url>: Allows you to specify a URL to use as the upload server base URL. Defaults to https://test-observability.herokuapp.com.
# -o / --output-file <file>: Where to output the logs to. Defaults to ./xcodebuild-logs-upload-<upload ID>.
# -c / --cache-directory <dir>: Where to cache the GitHub logs. Defaults to ~/Library/Caches/com.ably.testObservabilityLogs. Will be created if doesn’t exist.

set -e

# 1. Check dependencies.

if ! which jq > /dev/null
then
  echo "You need to install jq." 2>&1
  exit 1
fi

# 2. Grab command-line options.

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--upload-id) upload_id="$2"; shift ;;
        -u|--upload-server-base-url) upload_server_base_url="$2"; shift ;;
        -o|--output-file) output_file="$2"; shift ;;
        -c|--cache-directory) cache_directory="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [[ -z $upload_id ]]
then
  echo "You need to specify the upload ID (-i / --upload-id)." 2>&1
  exit 1
fi

if [[ -z $upload_server_base_url ]]
then
  upload_server_base_url="https://test-observability.herokuapp.com"
fi

if [[ -z $output_file ]]
then
  output_file="xcodebuild-logs-upload-${upload_id}"
fi

if [[ -z $cache_directory ]]
then
  cache_directory="${HOME}/Library/Caches/com.ably.testObservabilityLogs"
fi

# 3. Get the GitHub access token from the user. We don’t allow them to specify it on the command line.

# https://stackoverflow.com/questions/3980668/how-to-get-a-password-from-a-shell-script-without-echoing#comment4260181_3980904
read -s -p "Enter your GitHub access token (this will be used to fetch logs from the GitHub API): " github_access_token

if [[ -z $github_access_token ]]
then
  echo "\nYou need to specify a GitHub access token." 2>&1
  exit 1
fi

# 4. From the test observability server API, fetch the upload, to find the GitHub run ID, attempt number, job name, and iteration.

echo "Fetching upload ${upload_id} from ${upload_server_base_url}." 2>&1 

upload_json=$(curl --fail --header "Accept: application/json" "${upload_server_base_url}/uploads/${upload_id}")

# TIL I learned that `echo` will interpret backslash sequences, which we don’t want.
# Appparently in general printf is recommended over echo
# https://stackoverflow.com/questions/43528202/prevent-echo-from-interpreting-backslash-escapes
github_repository=$(printf '%s' $upload_json | jq --raw-output '.githubRepository')
github_run_id=$(printf '%s' $upload_json | jq --raw-output '.githubRunId')
github_run_attempt=$(printf '%s' $upload_json | jq --raw-output '.githubRunAttempt')
github_job=$(printf '%s' $upload_json | jq --raw-output '.githubJob')
iteration=$(printf '%s' $upload_json | jq --raw-output '.iteration')

echo "Upload comes from GitHub repository ${github_repository}. It has GitHub run ID ${github_run_id}, run attempt number ${github_run_attempt}, and job name ${github_job}. It corresponds to loop iteration ${iteration}."

# 5. Check whether we have a cached log for this job.
# (We cache the job logs because they can easily be ~1.5GB.)

log_file_name="github-log-${github_repository//\//-}-run-${github_run_id}-attempt-${github_run_attempt}-job-${github_job}"
log_file_path="${cache_directory}/${log_file_name}"

if [[ -f "${log_file_path}" ]]
then
  echo "GitHub job log file already exists at ${log_file_path}. Skipping download." 2>&1
else
  echo "GitHub job log file not yet downloaded." 2>&1

  # (Steps 6-8 are only if we don’t have a cached log for this job.)

  GITHUB_API_BASE_URL="https://api.github.com"

  # 6. From the GitHub API, fetch the jobs for this workflow run attempt.
  # https://docs.github.com/en/rest/reference/actions#list-jobs-for-a-workflow-run-attempt
  github_jobs_json=$(curl \
      --fail \
      -H "Authorization: token ${github_access_token}" \
      -H "Accept: application/vnd.github.v3+json" \
      "${GITHUB_API_BASE_URL}/repos/${github_repository}/actions/runs/${github_run_id}/attempts/${github_run_attempt}/jobs")

  # 7. From this list of jobs, find the one that corresponds to our upload.
  github_job_id=$(printf "%s" $github_jobs_json | jq \
  --arg jobName "${github_job}" \
  '.jobs[] | select(.name == $jobName) | .id')

  # TODO handle error, handle raw output, just cos it's number so what
  # TODO is this information that I should have just had in the upload in the first place?

  echo "Upload corresponds to GitHub job ID ${github_job_id}. Downloading logs. This may take a while."

  # 8. From the GitHub API, fetch the logs for this job and cache them.
  # https://docs.github.com/en/rest/reference/actions#download-job-logs-for-a-workflow-run

  if [[ ! -d "${cache_directory}" ]]
  then
    mkdir -p "${cache_directory}"
  fi

  curl \
      --fail \
      --location \
      -H "Authorization: token ${github_access_token}" \
      -H "Accept: application/vnd.github.v3+json" \
       "${GITHUB_API_BASE_URL}/repos/${github_repository}/actions/jobs/${github_job_id}/logs" > "${log_file_path}.partial"

  mv "${log_file_path}.partial" "${log_file_path}"

  echo "Saved GitHub job logs to ${log_file_path}."
fi

# 9. Extract the part of the logs that corresponds to the raw xcodebuild output for this iteration.

# https://stackoverflow.com/a/18870500

echo "Finding xcodebuild output for iteration ${iteration}."

xcodebuild_output_start_marker="ITERATION ${iteration}: BEGIN xcodebuild raw output"
xcodebuild_output_start_line_number=$(sed -n "/${xcodebuild_output_start_marker}/=" "${log_file_path}")

if [[ -z "${xcodebuild_output_start_line_number}" ]]
then
  echo "Couldn’t find start of xcodebuild raw output (couldn’t find marker \"${xcodebuild_output_start_marker}\")." 2>&1
  echo "This may be because the GitHub job hasn’t finished yet, or because the tests are not being run in a loop." 2>&1
  echo "You may need to delete the cached log file ${log_file_path}." 2>&1
  exit 1
fi

xcodebuild_output_end_marker="ITERATION ${iteration}: END xcodebuild raw output"
xcodebuild_output_end_line_number=$(sed -n "/${xcodebuild_output_end_marker}/=" "${log_file_path}")

if [[ -z "${xcodebuild_output_end_line_number}" ]]
then
  echo "Couldn’t find end of xcodebuild raw output (couldn’t find marker \"${xcodebuild_output_end_marker}\")." 2>&1
  exit 1
fi

# 10. Strip the GitHub-added timestamps (which just correspond to the time that `cat` was executed on the log file, and hence aren’t of any use) from the start of each line.

echo "Stripping GitHub timestamps."

# https://arkit.co.in/print-given-range-of-lines-using-awk-perl-head-tail-and-python/
sed -n "${xcodebuild_output_start_line_number},${xcodebuild_output_end_line_number} p" "${log_file_path}" | sed -e 's/^[^ ]* //' > "${output_file}"

echo "Wrote xcodebuild output to ${output_file}." 2>&1
