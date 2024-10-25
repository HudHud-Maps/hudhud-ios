#!/usr/bin/env bash
set -euo pipefail

if [ $CI_WORKFLOW = 'Internal TestFlight' ]
then
	../.tools/release-notes linear move-tickets --api-key $LINEAR_API_KEY --team "iOS"
fi