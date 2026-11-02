#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
[ "$(printf '' | sh scripts/next-version.sh)" = '0.0.1' ]
[ "$(printf '%s\n' v0.0.2 v0.0.10 v0.1.99 v0.0.3-beta | sh scripts/next-version.sh)" = '0.0.11' ]
[ "$(printf '%s\n' v0.0.1 v0.0.3 | sh scripts/next-version.sh)" = '0.0.4' ]
printf 'Version checks passed.\n'
