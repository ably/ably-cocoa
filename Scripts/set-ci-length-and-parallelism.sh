#!/bin/bash

set -e

# Usage:
# ./set-ci-length-and-parallelism.sh --workflows <num> --jobs-per-workflow <num>

# Check dependencies.
if ! which yq > /dev/null; then
  echo "You need to install yq." 2>&1
  exit 1
fi

# Grab and validate command-line options.

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --workflows)
      if [[ -z "$2" ]]; then
        echo "You must specify the number of workflows." 2>&1
        exit 1
      fi
      num_workflows="$2"
      shift
      ;;
    --jobs-per-workflow)
      if [[ -z "$2" ]]; then
        echo "You must specify the number of jobs per workflow." 2>&1
        exit 1
      fi
      jobs_per_workflow="$2"
      shift
      ;;
    *)
      echo "Unknown parameter passed: $1" 2>&1
      exit 1
      ;;
  esac
  shift
done

if [[ -z $num_workflows ]]; then
  echo "You need to specify the number of workflows (--workflows)." 2>&1
  exit 1
fi

if [[ ! $num_workflows =~ ^-?[0-9]+$ ]]; then
  echo "The number of workflows must be a number." 2>&1
  exit 1
fi

if [[ $num_workflows -lt 1 ]]; then
  echo "The number of workflows must be 1 or more." 2>&1
  exit 1
fi

if [[ -z $jobs_per_workflow ]]; then
  echo "You need to specify the number of jobs per workflow (--jobs-per-workflow)." 2>&1
  exit 1
fi

if [[ ! $jobs_per_workflow =~ ^-?[0-9]+$ ]]; then
  echo "The number of jobs per workflow must be a number." 2>&1
  exit 1
fi

if [[ $jobs_per_workflow -lt 1 ]]; then
  echo "The number of jobs per workflow must be 1 or more." 2>&1
  exit 1
fi

workflow_file_without_extension=".github/workflows/integration-test-iOS16_2"
workflow_file_extension=".yaml"

workflow_file="${workflow_file_without_extension}${workflow_file_extension}"
workflow_name=$(yq .name $workflow_file)

# First, we apply the number of jobs per workflow.

yq -i '(.jobs.check | key) = "check-1"' $workflow_file
yq -i "(.jobs.check-1.steps[] | select(.with.path == \"xcresult-bundles.tar.gz\")).with.name = \"xcresult-bundles-1.tar.gz\"" $workflow_file

for ((i=2; i <= $jobs_per_workflow; i += 1))
do
  yq -i ".jobs.check-${i} = .jobs.check-$(($i-1))" $workflow_file
  yq -i ".jobs.check-${i}.needs = [\"check-$(($i-1))\"]" $workflow_file
  yq -i "(.jobs.check-${i}.steps[] | select(.with.path == \"xcresult-bundles.tar.gz\")).with.name = \"xcresult-bundles-${i}.tar.gz\"" $workflow_file
done

# Now, we duplicate the workflow file the requested number of times.

mv $workflow_file "${workflow_file_without_extension}-1${workflow_file_extension}"

for ((i=1; i <= $num_workflows; i += 1))
do
  new_workflow_file="${workflow_file_without_extension}-${i}${workflow_file_extension}"

  if [[ $i -gt 1 ]]; then
    cp "${workflow_file_without_extension}-$((i-1))${workflow_file_extension}" $new_workflow_file
  fi

  yq -i ".name = \"${workflow_name} (workflow ${i})\"" $new_workflow_file
done
