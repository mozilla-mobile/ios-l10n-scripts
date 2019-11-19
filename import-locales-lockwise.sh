#! /usr/bin/env bash

if [ ! -d Lockbox.xcodeproj ]; then
    echo "Please run this from the project root that contains lockbox-ios.xcodeproj"
    exit 1
fi

dir=$(dirname "$0")
${dir}/import-locales.sh Lockbox.xcodeproj lockwiseios-l10n lockwise-ios.xliff
