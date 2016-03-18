#! /usr/bin/env python

#
# update-xliff.py <base_l10n_folder>
#
#  For each folder (locale) available in base_l10n_folder:
#
#  1. Read existing translations, store them in an array: IDs use the structure
#     file_name:string_id:source_hash. Using the hash of the source string
#     prevent from keeping an existing translation if the ID doesn't change
#     but the source string does.
#
#  2. Inject available translations in the reference XLIFF file, updating
#     the target-language where available on file elements.
#
#  3. Store the updated content in existing locale files, without backup.
#

from glob import glob
from lxml import etree
import argparse
import os

NS = {'x':'urn:oasis:names:tc:xliff:document:1.2'}

def indent(elem, level=0):
    # Prettify XML output
    # http://effbot.org/zone/element-lib.htm#prettyprint
    i = '\n' + level*'  '
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + '  '
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def main():
    # Base parameters, there should be no need to change these unless
    # there are more locales to exclude.
    reference_locale = 'en-US'
    target_language = 'en'
    xliff_filename = 'firefox-ios.xliff'
    excluded_locales = ['pl', reference_locale]

    parser = argparse.ArgumentParser()
    parser.add_argument('base_folder', help='Path to folder including subfolders for all locales')
    parser.add_argument('locales', default='*', nargs='*', help='Locales to process (default: %(default)s)')
    args = parser.parse_args()

    # Get a list of files to update (absolute paths)
    base_folder = os.path.realpath(args.base_folder)
    file_paths = []
    if args.locales == '*':
        for xliff_path in glob(base_folder + '/*/' + xliff_filename):
            parts = xliff_path.split(os.sep)
            if not parts[-2] in excluded_locales:
                file_paths.append(xliff_path)
    else:
        for locale in args.locales:
            if locale not in excluded_locales:
                file_paths.append(base_folder + '/' + locale + '/' + xliff_filename)
    file_paths.sort()

    for file_path in file_paths:
        print 'Updating %s' % file_path

        # Read the reference file XML
        reference_tree = etree.parse(os.path.join(base_folder, reference_locale, xliff_filename))
        reference_root = reference_tree.getroot()

        # Read localized file XML
        locale_tree = etree.parse(file_path)
        locale_root = locale_tree.getroot()

        # Using locale folder as locale code. In some cases we need to map this
        # value to a different locale code
        # http://www.ibabbleon.com/iOS-Language-Codes-ISO-639.html
        # See Bug 1193530, Bug 1160467.
        locale_code = file_path.split(os.sep)[-2]
        locale_mapping = {
            'bn-IN': 'bn',
            'ga-IE': 'ga',
            'nb-NO': 'nb',
            'nn-NO': 'nn',
            'sv-SE': 'sv'
        }
        if locale_code in locale_mapping:
            locale_code = locale_mapping[locale_code]

        # Store existing localizations
        translations = {}
        for trans_node in locale_root.xpath('//x:trans-unit', namespaces=NS):
            for child in trans_node.xpath('./x:target', namespaces=NS):
                file_name = trans_node.getparent().getparent().get('original')
                source_string = trans_node.xpath('./x:source', namespaces=NS)[0].text
                string_id = '%s:%s:%s' % (file_name, trans_node.get('id'), hash(source_string))
                translations[string_id] = child.text

        # Inject available translations in the reference XML
        for trans_node in reference_root.xpath('//x:trans-unit', namespaces=NS):
            file_name = trans_node.getparent().getparent().get('original')
            source_string = trans_node.xpath('./x:source', namespaces=NS)[0].text
            string_id = '%s:%s:%s' % (file_name, trans_node.get('id'), hash(source_string))
            updated = False
            translated = string_id in translations
            for child in trans_node.xpath('./x:target', namespaces=NS):
                if translated:
                    # Translation is available, update the target
                    child.text = translations[string_id]
                else:
                    # No translation available, remove the target
                    child.getparent().remove(child)
                updated = True

            if translated and not updated:
                # Translation is available, but reference has no target.
                # Create a target node and insert it after source.
                child = etree.Element('target')
                child.text = translations[string_id]
                trans_node.insert(1, child)

        # Update target-language where defined
        for file_node in reference_root.xpath('//x:file', namespaces=NS):
            if file_node.get('target-language'):
                file_node.set('target-language', locale_code)

        # Replace the existing locale file with the new XML content
        with open(file_path, 'w') as fp:
            # Fix indentations
            indent(reference_root)
            xliff_content = etree.tostring(
                                reference_tree,
                                encoding='UTF-8',
                                xml_declaration=True,
                                pretty_print=True
                            )
            fp.write(xliff_content)

if __name__ == '__main__':
    main()
