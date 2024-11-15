#!/bin/bash

# Generates Jazzy documentation: https://github.com/realm/jazzy
# This script performs without issues on CI. To generate docs locally see https://github.com/ably/ably-cocoa/issues/1438

jazzy \
  --objc \
  --clean \
  --author Ably \
  --module-version 1.2.34 \
  --umbrella-header Source/include/Ably/Ably.h \
  --framework-root Source \
  --module Ably \
  --sdk iphonesimulator \
  --readme Docs/Main.md \
  --output Docs/jazzy
