#! /usr/bin/env bash

#
# Assumes the following is installed:
#
#  git
#  brew
#  python via brew
#  virtualenv via pip in brew
#
# Syntax is:
# ./export-locales.sh (name of project file) (name of l10n repo) (name of xliff file) [clean]
#
# We can probably check all that for the sake of running this hands-free
# in an automated manner.
#

clean_run=false
if [ $# -ge 3 ]
then
    if [ $# -eq 4 ]
    then
        if [ "$4" == "clean" ]
        then
            clean_run=true
        else
            echo "Unknown parameter: $4"
            echo "Leave empty to reuse an existing venv, use 'clean' to create a new one"
            exit 1
        fi
    fi
    xcodeproj="$1"
    l10n_repo="$2"
    l10n_file="$3"
else
    echo "Not enough parameters."
    echo "Syntax: ./export-locales.sh (name of .xcodeproj file) (name of l10n repo) (name of xliff file) [clean]"
    echo "Example: ./export-locales.sh Client.xcodeproj firefoxios-l10n firefox-ios.xliff clean"
    echo "You should call this script via wrappers like export-locales-firefox.sh"
    exit 1
fi

if [ ! -d ${xcodeproj} ]
then
  echo "Please run this from the project root that contains ${xcodeproj}"
  exit 1
fi

if [ -d ${l10n_repo} ]
then
  echo "There already is a ${l10n_repo} checkout. Aborting to let you decide what to do."
  exit 1
fi

SDK_PATH=`xcrun --show-sdk-path`

SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If the virtualenv with the Python modules that we need doesn't exist,
# or a clean run was requested, create the virtualenv.
if [ ! -d export-locales-env ] || [ "${clean_run}" = true ]
then
    rm -rf export-locales-env || exit 1
    echo "Setting up new virtualenv..."
    virtualenv export-locales-env --python=python2.7 || exit 1
    source export-locales-env/bin/activate || exit 1
    # install libxml2
    CFLAGS=-I"$SDK_PATH/usr/include/libxml2" LIBXML2_VERSION=2.9.2 pip install lxml || exit 1
else
    echo "Reusing existing virtualenv found in export-locales-env"
    source export-locales-env/bin/activate || exit 1
fi

# Check out a clean copy of the l10n repo
git clone https://github.com/mozilla-l10n/${l10n_repo} || exit 1

# Export English base to /tmp/en.xliff
rm -f /tmp/en.xliff || exit 1
echo "Exporting en-US with xcodebuild"
xcodebuild -exportLocalizations -localizationPath /tmp -project ${xcodeproj} -exportLanguage en || exit 1
cp "/tmp/en.xcloc/Localized Contents/en.xliff" /tmp/en.xliff || exit 1

if [ ! -f /tmp/en.xliff ]
then
  echo "Export failed. No /tmp/en.xliff generated."
  exit 1
fi

# Fix the Focus export
/usr/bin/perl -p -i -e "s|Blockzilla/en.lproj/Intro.strings|Blockzilla/Intro.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|Blockzilla/en.lproj/InfoPlist.strings|Blockzilla/InfoPlist.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|Blockzilla/en.lproj/Intro.strings|Blockzilla/Intro.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|Blockzilla/en.lproj/Intents.strings|Blockzilla/Intents.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|ContentBlocker/en.lproj/InfoPlist.strings|ContentBlocker/InfoPlist.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|OpenInFocus/en.lproj/InfoPlist.strings|OpenInFocus/InfoPlist.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|CredentialProvider/en.lproj/InfoPlist.strings|CredentialProvider/InfoPlist.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|CredentialProvider/en.lproj/Localizable.strings|CredentialProvider/Localizable.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|lockbox-ios/Common/Resources/Strings/en.lproj/InfoPlist.strings|lockbox-ios/Common/Resources/Strings/InfoPlist.strings|g" /tmp/en.xliff
/usr/bin/perl -p -i -e "s|lockbox-ios/Common/Resources/Strings/en.lproj/Localizable.strings|lockbox-ios/Common/Resources/Strings/Localizable.strings|g" /tmp/en.xliff


# Create a branch in the repository
cd ${l10n_repo}
branch_name=$(date +"%Y%m%d_%H%M")
git branch ${branch_name}
git checkout ${branch_name}

# Copy the English XLIFF file into the repository and commit
cp /tmp/en.xliff en-US/${l10n_file} || exit 1
git add en-US/${l10n_file}
git commit -m "en-US: update ${l10n_file}"

# Update all locales
${SCRIPTS}/update-xliff.py . ${l10n_file} || exit 1

# Commit each locale separately
locale_list=$(find . -mindepth 1 -maxdepth 1 -type d  \( ! -iname ".*" \) | sed 's|^\./||g' | sort)
for locale in ${locale_list};
do
    # Exclude en-US and templates
    if [ "${locale}" != "en-US" ] && [ "${locale}" != "templates" ]
    then
        git add ${locale}/${l10n_file}
        git commit -m "${locale}: Update ${l10n_file}"
    fi
done

# Copy the en-US file in /templates
cp en-US/${l10n_file} templates/${l10n_file} || exit 1
# Clean up /templates removing target-language and translations
${SCRIPTS}/clean-xliff.py templates ${l10n_file} || exit 1
git add templates/${l10n_file}
git commit -m "templates: update ${l10n_file}"

echo
echo "NOTE"
echo "NOTE Use the following command to push the branch to Github where"
echo "NOTE you can create a Pull Request:"
echo "NOTE"
echo "NOTE   cd ${l10n_repo}"
echo "NOTE   git push --set-upstream origin $branch_name"
echo "NOTE"
echo
