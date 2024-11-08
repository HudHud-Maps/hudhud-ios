#!/bin/bash

if grep -q 'productName = "plugin:SwiftLint";' HudHud.xcodeproj/project.pbxproj; then
	echo "✅ SwiftLint part of build pipeline"
else
	echo "SwiftLint is not part of the build pipeline."
	echo "Please add it via the project settings under: HudHud -> Build Phases -> Run Build Tool Plug-ins"
	exit 1
fi