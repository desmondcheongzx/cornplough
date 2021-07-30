#!/bin/bash
sed 's/>.*$//' |
    sed 's/^.*</--to=/' |
    awk '/open list/ {print "--cc=" $1} !/open list/' |
    paste -s -d ' '
