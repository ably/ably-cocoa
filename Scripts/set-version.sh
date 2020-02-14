#!/bin/bash
set -e

source "$(dirname "$0")/version-constants.sh"

if [[ $(git diff --stat) != '' ]]; then
  echo "ERROR: Your Git working directory is dirty."
  echo "This script creates a commit and a tag, so it needs a clean starting point."
  exit 1
fi

prefix="$VERSION_CONFIG_VAR = "
version_config=$(cat $VERSION_CONFIG_FILE)
OLD_VERSION=${version_config:${#prefix}}
NEW_VERSION="$1"

if [[ -z "NEW_VERSION" ]]; then
  echo "ERROR: You must specify a version."
  exit 1
fi

echo "New version: $NEW_VERSION"
echo "Old version: $OLD_VERSION"

# Assign new version
echo "$VERSION_CONFIG_VAR = $NEW_VERSION" > $VERSION_CONFIG_FILE

sed -i '' -e 's/'"$OLD_VERSION"'/'"$NEW_VERSION"'/g' README.md
sed -i '' -e 's/'"$OLD_VERSION"'/'"$NEW_VERSION"'/g' Spec/RealtimeClientConnection.swift

git add README.md
git add Spec/RealtimeClientConnection.swift
git add Version.xcconfig
git commit -m "Bump version to $NEW_VERSION."

