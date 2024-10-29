#!/bin/sh
set -euo pipefail

if [ ${CI_XCODEBUILD_EXIT_CODE} != 0 ]
then
	echo "Previous Build step failed, aborting"
	exit 1
fi

VERSION=$(cat ../HudHud.xcodeproj/project.pbxproj | grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | tr -d ';' | tr -d ' ')
echo "Found Build Version:" $VERSION


if [[ $CI_WORKFLOW = 'Internal TestFlight' ]]
then
	
	if [[ -n $CI_APP_STORE_SIGNED_APP_PATH ]]; # checks if there is an AppStore signed archive after running xcodebuild
	then
		
		echo "Running Internal TestFlight"
		echo "moving tickets to 'Available on TestFlight' column"
		../.tools/release-notes linear move-tickets --api-key $LINEAR_API_KEY --team "iOS"
		
		NEW_TAG=TestFlight/Internal/$VERSION\($CI_BUILD_NUMBER\)
		echo "Tag commit with '$NEW_TAG'"
		git tag $NEW_TAG
		git push --tags "https://${GIT_AUTH}@github.com/HudHud-Maps/hudhud-ios.git"

	fi
fi

if [[ $CI_WORKFLOW = 'External TestFlight' ]]
then
	
	if [[ -n $CI_APP_STORE_SIGNED_APP_PATH ]]; # checks if there is an AppStore signed archive after running xcodebuild
	then
		
		echo "Running External TestFlight"
		echo "moving tickets to 'Done' column"
		../.tools/release-notes linear move-tickets --api-key $LINEAR_API_KEY --team "iOS" --column "Available on TestFlight" --destination "Done"
		
		NEW_TAG=TestFlight/External/$VERSION\($CI_BUILD_NUMBER\)
		echo "Tag commit with '$NEW_TAG'"
		git tag $NEW_TAG
		git push --tags "https://${GIT_AUTH}@github.com/HudHud-Maps/hudhud-ios.git"
		
	fi
fi
