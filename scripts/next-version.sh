#!/bin/sh
set -eu
awk '
    /^v0[.]0[.][0-9]+$/ {
        number = substr($0, 6) + 0
        if (number > highest) highest = number
    }
    END { printf "0.0.%d\n", highest + 1 }
'
