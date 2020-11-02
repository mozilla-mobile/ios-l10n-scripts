//
//  export.swift
//  ios-l10n-tools
//
//  Created by Jeff Boek on 11/2/20.
//

import Foundation
//    locale_mapping = {
//        'es-ES': 'es',
//        'ga-IE': 'ga',
//        'nb-NO': 'nb',
//        'nn-NO': 'nn',
//        'sv-SE': 'sv',
//        'tl'   : 'fil',
//        'zgh'  : 'tzm',
//        'sat'  : 'sat-Olck'
private let LOCALE_MAP = [
    "en-US" : "en",
    "sat-Olck": "sat"
]

struct ExportTask {
    let xcodeProjPath: String
    let l10nRepoPath: String
    let locales: [String]
    
    private let queue = DispatchQueue(label: "backgroundQueue", attributes: .concurrent)
    private let EXCLUDED_TRANSLATIONS: Set<String> = ["CFBundleName", "CFBundleDisplayName", "CFBundleShortVersionString"]
    private let EXPORT_BASE_PATH = "/tmp/ios-localization"
    
    private func exportLocales() {
        let command = "xcodebuild -exportLocalizations -project \(xcodeProjPath) -localizationPath \(EXPORT_BASE_PATH)"
        let command2 = locales
            .map { LOCALE_MAP[$0] ?? $0 }
            .map { "-exportLanguage \($0)" }.joined(separator: " ")

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command + " " + command2]
        try! task.run()
        task.waitUntilExit()
    }
    
    private func handleXML(path: String, locale: String) {
        let locale = LOCALE_MAP[locale] ?? locale
        let url = URL(fileURLWithPath: path.appending("/\(locale).xcloc/Localized Contents/\(locale).xliff"))
        let xml = try! XMLDocument(contentsOf: url, options: .nodePreserveWhitespace)
        xml.children?.first?.children?.forEach { node in
            guard let node = node as? XMLElement else { return }
            let translations = try! node.nodes(forXPath: "body/trans-unit")
            translations.forEach {
                guard let translation = $0 as? XMLElement else { return }
                if translation.attribute(forName: "id")?.stringValue.map(EXCLUDED_TRANSLATIONS.contains) == true {
                    translation.detach()
                }
            }
            let newTranslations = try! node.nodes(forXPath: "body/trans-unit")
            if newTranslations.isEmpty {
                node.detach()
            }
        }
        
        try! xml.xmlString.write(to: url, atomically: true, encoding: .utf16)
    }
    
    
    private func copyToL10NRepo(locale: String) {
        let exportLocale = LOCALE_MAP[locale] ?? locale
        let source = URL(fileURLWithPath: "\(EXPORT_BASE_PATH)/\(exportLocale).xcloc/Localized Contents/\(exportLocale).xliff")
        let destination = URL(fileURLWithPath: "\(l10nRepoPath)/\(locale)/firefox-ios.xliff")
        try! FileManager.default.replaceItemAt(destination, withItemAt: source)
    }

    
    func run() {
        exportLocales()
        locales.forEach { locale in
            queue.async {
                handleXML(path: EXPORT_BASE_PATH, locale: locale)
                copyToL10NRepo(locale: locale)
            }
        }

        print(xcodeProjPath, l10nRepoPath, locales)
    }
}
