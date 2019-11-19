#! /usr/bin/env bash

if [ ! -d Client.xcodeproj ]; then
    echo "Please run this from the project root that contains Client.xcodeproj"
    exit 1
fi

dir=$(dirname "$0")
${dir}/import-locales.sh Client.xcodeproj firefoxios-l10n firefox-ios.xliff