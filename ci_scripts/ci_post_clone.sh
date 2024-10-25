#!/usr/bin/env bash
set -euo pipefail

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

if [ $CI_WORKFLOW = 'Internal TestFlight' ]
then
	../.tools/release-notes linear testflight --file ../TestFlight/WhatToTest.en-US.txt --api-key $LINEAR_API_KEY --team "iOS"
fi



