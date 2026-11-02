#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/liftlink-preview-test.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
mkdir -p build/module-cache
swiftc -module-cache-path "$PWD/build/module-cache" Sources/LinkPreview.swift tests/LinkPreview/main.swift -o "$test_dir/link-preview-test"
"$test_dir/link-preview-test"
