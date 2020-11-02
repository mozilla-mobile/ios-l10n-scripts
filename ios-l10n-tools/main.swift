//
//  main.swift
//  ios-l10n-tools
//
//  Created by Jeff Boek on 10/21/20.
//

// todo: copy over
//
//required_ids = [
//    'NSCameraUsageDescription',
//    'NSLocationWhenInUseUsageDescription',
//    'NSMicrophoneUsageDescription',
//    'NSPhotoLibraryAddUsageDescription',
//    'ShortcutItemTitleNewPrivateTab',
//    'ShortcutItemTitleNewTab',
//    'ShortcutItemTitleQRCode',
//]
// from en locale if missing or app will crash on those locales.

// run this by flod if we still need this
//# Using locale folder as locale code. In some cases we need to map this
//    # value to a different locale code
//    # http://www.ibabbleon.com/iOS-Language-Codes-ISO-639.html
//    # See Bug 1193530, Bug 1160467.
//    locale_code = file_path.split(os.sep)[-2]
//    locale_mapping = {
//        'es-ES': 'es',
//        'ga-IE': 'ga',
//        'nb-NO': 'nb',
//        'nn-NO': 'nn',
//        'sv-SE': 'sv',
//        'tl'   : 'fil',
//        'zgh'  : 'tzm',
//        'sat'  : 'sat-Olck'
//    }
//
//
//
// and this
//for locale in ${locale_list};
//do
//    # Exclude en-US and templates
//    if [ "${locale}" != "en-US" ] && [ "${locale}" != "templates" ]

import Foundation
import ArgumentParser

let l10nPath = "/Users/boek/git/mozilla-l10n/firefoxios-l10n"

struct L10NTools: ParsableCommand {
    @Option(help: "Path to the project")
    var projectPath: String
    
    @Flag(help: "To determine if we should run the export task.")
    var export = false
    
    
    
    mutating func run() throws {
        let shippingLocales = URL(fileURLWithPath: projectPath).deletingLastPathComponent().appendingPathComponent("shipping_locales.txt")
        let locales = try! String(contentsOf: shippingLocales).components(separatedBy: .newlines).filter { !$0.isEmpty }
        if export {
            ExportTask(xcodeProjPath: projectPath, l10nRepoPath: l10nPath, locales: locales).run()
        }
    }
}

L10NTools.main()
dispatchMain()
