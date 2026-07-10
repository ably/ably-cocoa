#!/usr/bin/env bash

# Imports the contents of another git repository, at a given commit, into a
# directory of this repository.
#
# Usage: Scripts/import-repo-contents.sh <git-url> <commit-sha> <dest-dir>
#
# Only files tracked by git at the given commit are imported (via
# `git archive`); submodule paths come across as empty directories, not
# content. The commit SHA must be a full SHA (fetching an abbreviated SHA is
# not supported by all servers).
#
# This exists so that "import the contents of repo X at commit Y" commits are
# reproducible: to swap in a newer version of the imported repo, drop the
# import commit, rerun this script at the new SHA, and recommit.

set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <git-url> <commit-sha> <dest-dir>" >&2
    exit 1
fi

url=$1
sha=$2
dest=$3

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git init --quiet "$tmp"
git -C "$tmp" remote add origin "$url"
git -C "$tmp" fetch --quiet --depth 1 origin "$sha"

mkdir -p "$dest"
git -C "$tmp" archive "$sha" | tar -x -C "$dest"

echo "Imported $url @ $sha into $dest"
