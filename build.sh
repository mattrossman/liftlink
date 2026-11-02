#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p build/LiftLink.app/Contents/MacOS build/module-cache
cp Info.plist build/LiftLink.app/Contents/Info.plist
minimum_version=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" Info.plist)
swiftc -target "$(uname -m)-apple-macosx$minimum_version" -module-cache-path "$PWD/build/module-cache" Sources/main.swift Sources/LinkPreview.swift -o build/LiftLink.app/Contents/MacOS/LiftLink
signing_identity=${LIFTLINK_SIGNING_IDENTITY:-}
if [ -z "$signing_identity" ] && [ -f .signing-identity ]; then
    signing_identity=$(cat .signing-identity)
fi
codesign --force --sign "${signing_identity:--}" build/LiftLink.app
