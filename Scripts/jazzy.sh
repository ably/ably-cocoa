#!/bin/bash

# Generates Jazzy documentation: https://github.com/realm/jazzy

jazzy \
  --objc \
  --author Ably \
  --module-version 1.2.10 \
  --umbrella-header Source/Ably.h \
  --framework-root . \
  --module Ably \
  --exclude="*/ARTPushActivationStateMachine.h","*/ARTPushActivationStateMachine+Private.h" \
  --output Docs/jazzy
