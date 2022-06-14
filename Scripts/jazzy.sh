#!/bin/bash

# Generates Jazzy documentation: https://github.com/realm/jazzy

jazzy \
  --objc \
  --clean \
  --author Ably \
  --module-version 1.2.10 \
  --umbrella-header Source/Ably.h \
  --framework-root . \
  --module Ably \
  --output Docs/jazzy
