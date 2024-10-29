#!/bin/sh
set -euo pipefail

env

if [ ${CI_XCODEBUILD_EXIT_CODE} != 0 ]
then
	exit 1
fi

VERSION=$(cat ./project.pbxproj | grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | tr -d ';' | tr -d ' ')

if [[ $CI_WORKFLOW = 'Internal TestFlight' ]]
then
	
	if [[ -n $CI_APP_STORE_SIGNED_APP_PATH ]]; # checks if there is an AppStore signed archive after running xcodebuild
	then
		
		../.tools/release-notes linear move-tickets --api-key $LINEAR_API_KEY --team "iOS"
		git tag TestFlight/Internal/$VERSION\($CI_BUILD_NUMBER\)
		git push --tags "https://${GIT_AUTH}@github.com/HudHud-Maps/hudhud-ios.git"

	fi
fi

if [[ $CI_WORKFLOW = 'External TestFlight' ]]
then
	
	if [[ -n $CI_APP_STORE_SIGNED_APP_PATH ]]; # checks if there is an AppStore signed archive after running xcodebuild
	then
		
		../.tools/release-notes linear move-tickets --api-key $LINEAR_API_KEY --team "iOS" --column "Available on TestFlight" --destination "Done"
		git tag TestFlight/External/$VERSION\($CI_BUILD_NUMBER\)
		git push --tags "https://${GIT_AUTH}@github.com/HudHud-Maps/hudhud-ios.git"
		
	fi
fi
