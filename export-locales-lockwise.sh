#! /usr/bin/env bash

# Export new l10n strings for Focus

dir=$(dirname "$0")
${dir}/export-locales.sh Lockbox.xcodeproj lockwiseios-l10n lockwise-ios.xliff
