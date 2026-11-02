#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p build/LinkCopier.app/Contents/MacOS build/module-cache
cp Info.plist build/LinkCopier.app/Contents/Info.plist
swiftc -module-cache-path "$PWD/build/module-cache" Sources/main.swift -o build/LinkCopier.app/Contents/MacOS/LinkCopier
codesign --force --sign 'Link Copier Local Development' build/LinkCopier.app
