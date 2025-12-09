#!/bin/bash

# Generates Jazzy documentation: https://github.com/realm/jazzy

bundle exec jazzy \
  --objc \
  --clean \
  --author Ably \
  --module-version 1.2.55 \
  --umbrella-header Source/include/Ably/AblyPublic.h \
  --framework-root Source \
  --module Ably \
  --sdk iphonesimulator \
  --readme Docs/Main.md \
  --output Docs/jazzy
