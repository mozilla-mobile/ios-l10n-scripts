# Firefox for iOS - Build Tools 🛠

# Introduction

To help automate the building process for the various targets and release channels we use Fastlane (https://github.com/fastlane) for hooking up all the plumbing to produce our builds. Firefox's setup is unique in that:

* The application is localized in 40+ locales. We have a large comminuty of localizers who participate in the process on Poodle (http://pootle.translatehouse.org/). Because of this, the application is localized in a non-standard way compared to the way iOS handles it. We have various python scripts in the project that adapt the output from our community into formats which Xcode is more accustomed to.
* Firefox follows a train development model (https://en.wikipedia.org/wiki/Software_release_train). At any given time, we are maintaining a 'next release' branch and a development branch. To accomodate the differences between our trains, we have 3 release channels: `Nightly`, `Beta`, and `Release`.

# Setup

To get started with using the build tools, you'll need to install the following dependencies:

_Fastlane_ (https://github.com/fastlane/fastlane) `gem install fastlane`

_Badge_ (https://github.com/HazAT/badge) `gem install badge`

_pip_ (https://pip.pypa.io/en/stable/) `easy_install pip`

_virtualenv_ (https://virtualenv.pypa.io/en/stable/) `pip install virtualenv`

_Carthage_ (https://github.com/Carthage/Carthage) `brew install carthage`

_ImageMagick_ (http://www.imagemagick.org/script/index.php) `brew install imagemagick`

After grabbing all of the dependencies, clone down this Github repo. By default, Firefox for iOS is configured to look for a `build-tools` directory at the same level as the `firefox-ios` repo:

`git clone https://github.com/mozilla/firefox-ios-build-tools.git build-tools`

Before you can start building, you'll need to add your Apple ID and change the Team IDs in the Appfile. The Apple ID and Team ID are used to communicate to the iTunes connect portal to upload and retrieve information about the latest TestFlight submissions.

# Building

To start building Firefox using Fastlane, navigate to the root directory of `firefox-ios` and run any of the following commands:

`fastlane l10n build:<build_number>` generates a FennecAurora build for localizers to test with. An enterprise binary is generated and uploaded to our the distribution page on `people.mozilla.org/iosbuilds`.

`fastlane nightly` generates a Nightly configured binary from the current branch, submits it to Testflight, and generates a tag containing all exported localizations and code. On completion, the script will poll iTunes connect until the build has been processed and automatically release it to internal testers.

`fastlane beta adjust_sandbox_key:<key>` generates a Beta configured binary from the current branch. The binary is submitted to TestFlight and the code is tagged in git. The script does not poll until iTunes processes the build.

`fastlane release adjust_production_key:<key>` generates a Release configured binary from the current branch and performs the same series of actions as Beta except configured for a production release.

For both the Beta and Release builds, an API key for use in Adjust (https://www.adjust.com/) for the sandbox and production environments should be passed in as a parameter to the script call.


