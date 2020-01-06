#!/bin/sh
# Adapted from https://gist.github.com/darvin/96a3af399d0b970a59b1
set -x

security delete-keychain ios-build.keychain
rm -f ~/Library/MobileDevice/Provisioning\ Profiles/*
