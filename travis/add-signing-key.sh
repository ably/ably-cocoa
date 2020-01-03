#!/bin/sh
# Adapted from https://gist.github.com/darvin/96a3af399d0b970a59b1
set -x

pushd travis/
KEY_CHAIN=ios-build.keychain
security create-keychain -p travis $KEY_CHAIN
security default-keychain -s $KEY_CHAIN
security unlock-keychain -p travis $KEY_CHAIN
security set-keychain-settings -t 3600 -u $KEY_CHAIN
wget https://developer.apple.com/certificationauthority/AppleWWDRCA.cer
security import AppleWWDRCA.cer -k ~/Library/Keychains/$KEY_CHAIN -A /usr/bin/codesign
security import ably-cocoa-soak-test.cer -k ~/Library/Keychains/$KEY_CHAIN -A /usr/bin/codesign
security import ably-cocoa-soak-test.p12 -k ~/Library/Keychains/$KEY_CHAIN -P '' -A /usr/bin/codesign
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp ably-cocoa-soak-test.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/f0f49cb2-b7ef-4997-af89-2e85ca66b16b.mobileprovision

# From https://docs.travis-ci.com/user/common-build-problems/#mac-macos-sierra-1012-code-signing-errors
security set-key-partition-list -S apple-tool:,apple: -s -k travis $KEY_CHAIN
