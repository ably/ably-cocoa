# Given the ID of a upload on the test observability server, retrieves the raw xcodebuild output for that test run. Only works for tests that were run in a loop.

# Usage:
# ./fetch-logs-for-test-observability-server-upload.sh \
#   --upload-id <id> 

# Options:
# -i / --upload-id <id>: The ID of a upload saved on the test observability server.
# -u / --upload-server-base-url <url>: Allows you to specify a URL to use as the upload server base URL. Defaults to https://test-observability.herokuapp.com.
# -o / --output-file <file>: Where to output the logs to. Defaults to ./xcodebuild-logs-upload-<upload ID>.

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

# 3. From the test observability server API, fetch the upload, to find the GitHub run ID, attempt number, and job name.

echo "Fetching upload ${upload_id} from ${upload_server_base_url}." 2>&1 

upload_json=$(curl --fail --header "Accept: application/json" "${upload_server_base_url}/uploads/${upload_id}")

# TIL I learned that `echo` will interpret backslash sequences, which we don’t want.
# Appparently in general printf is recommended over echo
# https://stackoverflow.com/questions/43528202/prevent-echo-from-interpreting-backslash-escapes
github_run_id=$(printf '%s' $upload_json | jq --raw-output '.githubRunId')
github_run_attempt=$(printf '%s' $upload_json | jq --raw-output '.githubRunAttempt')
github_job=$(printf '%s' $upload_json | jq --raw-output '.githubJob')

echo "Upload has GitHub run ID ${github_run_id}, run attempt number ${github_run_attempt}, and job name ${github_job}."

# 4. Check whether we have a cached log for this job.
# (We cache the job logs because they can easily be ~1.5GB.)

# (Steps 5-8 are only if we don’t have a cached log for this job.)

# 5. From the GitHub API, fetch the jobs for this workflow run attempt.
# https://docs.github.com/en/rest/reference/actions#list-jobs-for-a-workflow-run-attempt

# 6. From this list of jobs, find the one that corresponds to our upload.

# 7. From the GitHub API, fetch a URL for the logs for this job.
# https://docs.github.com/en/rest/reference/actions#download-job-logs-for-a-workflow-run

# 8. Fetch the logs for this job and cache them.

# 9. Extract the part of the logs that corresponds to the raw xcodebuild output for this iteration.

# 10. Strip the GitHub-added timestamps (which just correspond to the time that `cat` was executed on the log file, and hence aren’t of any use) from the start of each line.

# 11. Write the output file.
