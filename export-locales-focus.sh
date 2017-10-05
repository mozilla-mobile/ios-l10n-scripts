#! /usr/bin/env bash

# Export new l10n strings for Focus

dir=$(dirname "$0")
${dir}/export-locales.sh Blockzilla.xcodeproj focusios-l10n focus-ios.xliff
