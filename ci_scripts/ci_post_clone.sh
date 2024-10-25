#!/usr/bin/env bash
set -euo pipefail

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

../.tools/release-notes linear testflight --file ../TestFlight/WhatToTest.en-US.txt --api-key $LINEAR_APIKEY --team "iOS"

