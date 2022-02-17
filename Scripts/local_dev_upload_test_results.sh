#!/bin/bash

export TEST_OBSERVABILITY_SECRET="abc123"
export GITHUB_SHA="fakesha"
export GITHUB_REF_NAME="fake-ref-name"
export GITHUB_RETENTION_DAYS="30"
export GITHUB_ACTION="fake-action"
export GITHUB_RUN_NUMBER="132423"
export GITHUB_RUN_ID="fake-run-id"
export GITHUB_RUN_ATTEMPT="1"
export GITHUB_BASE_REF="main"
export GITHUB_HEAD_REF="my-branch"
export GITHUB_JOB="fake-job"

./Scripts/upload_test_results.sh --iteration 1 --upload-server-base-url "http://localhost:3000"
