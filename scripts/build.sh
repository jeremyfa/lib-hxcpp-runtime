#!/bin/bash
#fail on errors
set -e
cd "$(dirname "$0")"

haxe build.hxml
haxelib run hxcpp build.cppia "$@"
