#!/bin/bash

#
# Configuration
#

BRANCH=jhugman/Bug1407702—add-user-state-to-screengraph
CARTHAGE_BRANCH=screenshots
REMOTE=fxios@wopr.norad.org:/home/fxios/public_html/screenshots/fxios/v10/

#
# Decide what screenshots to make on this machine
#

LOCALES=$*
if [ $# -eq 0 ]; then
  case "$(hostname)" in
    Builder1.local)
      LOCALES="af ar ast az bg bn br bs ca cs cy da de dsb el en-GB en-US eo es es-AR"
      ;;
    Builder2.local)
      LOCALES="es-CL es-MX eu fa fr ga-IE gd gl he hi-IN hsb hu hy-AM ia id is it ja kab kk"
      ;;
    Builder3.local)
      LOCALES="km kn ko lo lt lv ml ms my nb-NO ne-NP nl nn-NO or pa-IN pl pt-BR pt-PT rm ro"
      ;;
    Builder4.local)
      LOCALES="ru ses si sk sl sq sv-SE ta te th tl tr uk ur uz zh-CN zh-TW"
      ;;
    *)
      echo "Unknown machine, not sure what to do"
      exit 1
      ;;
  esac
fi

echo "$(date) Making screenshots for $LOCALES"

#
# Wipe workspace on every run
#

rm -rf firefox-ios-l10n-screenshots

#
# Clone projects
#

echo "$(date) Cloning mozilla-mobile/firefox-ios"
git clone --depth 1 --single-branch --branch "$BRANCH" https://github.com/mozilla-mobile/firefox-ios.git firefox-ios-l10n-screenshots >> firefox-ios-l10n-screenshots.log 2>&1
cd firefox-ios-l10n-screenshots

#
# Run Carthage. Previously we would just grab a tar file, which speeds things up considerably. That
# does not work anymore because of strange Fuzi / libxml errors that I have not been able to explain.
#

#echo "$(date) Downloading Carthage-$CARTHAGE_BRANCH.bz2"
#curl -O http://wopr.norad.org/~sarentz/fxios/Carthage-$CARTHAGE_BRANCH.tar.bz2 >> ../firefox-ios-l10n-screenshots.log 2>&1
#echo "$(date) Extracting Carthage-$CARTHAGE_BRANCH.tar.bz2"
#tar xfj Carthage-$CARTHAGE_BRANCH.tar.bz2 >> ../firefox-ios-l10n-screenshots.log 2>&1

echo "$(date) Running ./bootstrap.sh"
./bootstrap.sh >> ../firefox-ios-l10n-screenshots.log 2>&1

#
# Clone the l10n scripts and import locales
#

echo "$(date) Cloning mozilla-mobile/ios-l10n-scripts"
git clone https://github.com/mozilla-mobile/ios-l10n-scripts.git >> ../firefox-ios-l10n-screenshots.log 2>&1

echo "$(date) Importing locales"
./ios-l10n-scripts/import-locales-firefox.sh >> ../firefox-ios-l10n-screenshots.log 2>&1


#
# Run Fastlane and upload results
#

mkdir l10n-screenshots

for lang in $LOCALES; do
    echo "$(date) Snapshotting $lang"
    mkdir "l10n-screenshots/$lang"
    fastlane snapshot --project Client.xcodeproj --scheme L10nSnapshotTests \
        --skip_open_summary \
        --derived_data_path l10n-screenshots-dd \
        --erase_simulator --localize_simulator \
        -i "11.0.1" --devices "iPhone SE" --languages "$lang" \
        --output_directory "l10n-screenshots/$lang" > "l10n-screenshots/$lang/snapshot.txt" 2>&1
    # Generate the gallery
    rm -f "l10n-screenshots/$lang/screenshots.html"
    ../ios-l10n-scripts/gallery.py "l10n-screenshots/$lang" > "l10n-screenshots/$lang/gallery.html"
    # Sync all content, in case one previously failed
    echo "$(date) Syncing screenshots to $REMOTE"
    rsync -avzhe ssh l10n-screenshots/* "$REMOTE" >> ../firefox-ios-l10n-screenshots.log 2>&1
done

# Do a final sync for all content, in case one previously failed
echo "$(date) Syncing screenshots to $REMOTE"
rsync -avzhe ssh l10n-screenshots/* "$REMOTE" >> ../firefox-ios-l10n-screenshots.log 2>&1

