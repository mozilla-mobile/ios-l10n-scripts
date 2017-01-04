#! /usr/bin/env bash

# Export new l10n strings for Focus

dir=$(dirname "$0")
${dir}/export-locales.sh Client.xcodeproj firefoxios-l10n firefox-ios.xliff
