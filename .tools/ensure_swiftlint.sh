#!/bin/bash

if grep -q 'productName = "plugin:SwiftLint";' ../HudHud.xcodeproj/project.pbxproj; then
	echo "✅ SwiftLint part of build pipeline"
else
	echo "SwiftLint not part of build pipeline."
	echo "Please add it in the project settings under: HudHud -> Build Phases -> Run Build Tool Plug-ins"
	exit 1
fi