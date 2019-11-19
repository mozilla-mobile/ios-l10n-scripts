#!/usr/bin/env python

#
# strings-import.py project.xcodeproj strings-directory
#

import argparse
import glob
import os
import sys
import fnmatch

from mod_pbxproj import XcodeProject, PBXFileReference, PBXBuildFile, PBXVariantGroup, PBXGroup

TARGETS = {
    "Client":              {"path": "Client"},
    "NotificationService": {"path": "Extensions/NotificationService"},
    "ShareTo":             {"path": "Extensions/ShareTo"},
    "Today":               {"path": "Extensions/Today"},
    "Shared":              {"path": "Shared"},
    "Firefox Lockbox":     {"path": "lockbox-ios/**", "groupName": "lockbox-ios"},
    "CredentialProvider":  {"path": "CredentialProvider/**"}
}

LOCKBOX_TARGETS = [
    "Firefox Lockbox",
    "CredentialProvider"
]

LOCALES_TO_SKIP = []

def get_groups(project):
    return [group for group in project.objects.values() if group.get('isa') == 'PBXGroup']

def find_group(project, path):
    for group in project.objects.values():
        if group.get('isa') == 'PBXGroup':
            if group.get('path') == path:
                return group

def find_target(project, name):
    for target in project.get_build_phases('PBXNativeTarget'):
        if target['name'] == name:
            return target

def find_resources_phase(project, target):
    if not target:
        return None
    build_phases = target['buildPhases']
    for build_phase_id in target['buildPhases']:
        phase = project.objects.get(build_phase_id)
        if not phase:
            continue
        if phase.get('isa') == 'PBXResourcesBuildPhase':
            return phase

# TODO This should come from the transformed XLIFF files
def paths_for_localized_resources(path):
    paths = [p for p in glob.glob(path + "/*.lproj/*.strings")]

    # this script is run with python 2.7 which doesn't support ** in glob searches :(
    if path.endswith("/**"):
        paths = []
        for root, dirnames, filenames in os.walk(path[:-3]):
            for filename in fnmatch.filter(filenames, '*.strings'):
                paths.append(os.path.join(root, filename))

        print paths
        return paths
    else:
        return [p for p in glob.glob(path + "/*.lproj/*.strings")]


# TODO Rewrite to make more robust
def locale_name_from_path(path):
    directory_path = os.path.dirname(path)
    lproj_name = directory_path.split(os.sep)[-1]
    return lproj_name.split(".")[0]

def add_file_reference(project, path, variant_group):
    file_reference = PBXFileReference.Create(path, name=locale_name_from_path(path), tree="<group>")
    project.objects[file_reference.id] = file_reference
    variant_group.add_child(file_reference)

    project.modified = True

    return file_reference

def file_reference_exists(project, path, variant_group):
    for id in project.get_ids():
        obj = project.objects[id]
        if obj and obj.get('isa') == "PBXFileReference" and obj.get('path') == path:
            print "Found file reference for " + obj.get('path')
            return True

    print "Could not file file reference for " + path

    return False


def find_parent_group(project, group_id):
    for group in get_groups(project):
        if group.has_child(group_id):
            return group

    return None

def variant_in_group(project, variant_group_id, parent_group_id):
    group = find_parent_group(project, variant_group_id)
    if group:
        if group.id == parent_group_id:
            return True
        return variant_in_group(project, group.id, parent_group_id)

    return False

def get_or_add_variant_group(project, name, parent_group, phase):
    print "Looking for " + name + " in parent group " + str(parent_group.id) + " | " + str(parent_group.get('name'))
    for variant_group in project.objects.values():
        if variant_group.get('isa') == 'PBXVariantGroup':

            variant_group_name = variant_group.get('name')
            if variant_group_name == name or variant_group_name == name.replace("strings", "storyboard", 1) or variant_group_name == name.replace("strings", "xib", 1):
                # parent_group.has_child only checks one level 
                # but Localizable.strings is located in lockbox-ios/Common/Resources/Strings
                if variant_in_group(project, variant_group.id, parent_group.id):
                    print "Found a variant_group for " + variant_group_name
                    return variant_group

    print "Creating variant group " + str(name) + " under " + str(parent_group.id)
    variant_group = PBXVariantGroup.Create(name)
    project.objects[variant_group.id] = variant_group
    parent_group.add_child(variant_group)

    build_file = PBXBuildFile.Create(variant_group)
    project.objects[build_file.id] = build_file
    phase.add_build_file(build_file)

    project.modified = True

    return variant_group

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("xcode_project", help="Location of XCode project")
    args = parser.parse_args()

    project = XcodeProject.Load(args.xcode_project + "/project.pbxproj")
    if not project:
        print "Can't open ", args.xcode_project + "/project.pbxproj"
        sys.exit(1)

    for target_name in TARGETS.keys():
        target = find_target(project, target_name)
        if not target:
            print "Can't find target ", target_name
            continue

        group_name = target_name
        if "groupName" in TARGETS[target_name]:
            group_name = TARGETS[target_name]["groupName"]

        parent_group = find_group(project, group_name)
        if not parent_group:
            print "Can't find group ", group_name
            continue

        print "found ", target_name

        phase = find_resources_phase(project, target)
        if not phase:
            print "Can't find 'PBXResourcesBuildPhase' phase for target ", target_name
            sys.exit(1)

        if target and parent_group and phase:
            for path in paths_for_localized_resources(TARGETS[target_name]["path"]):
                locale_name = locale_name_from_path(path)
                if locale_name in LOCALES_TO_SKIP:
                    continue

                print "%s (%s): %s" % (target_name, locale_name, path)
                file_name = os.path.basename(path)

                variant_group = get_or_add_variant_group(project, file_name, parent_group, phase)

                # This is hacky - Trying to add these files as group relative to see if we can
                # get rid of the xx.lproj part in the exported filenames. (Does not work)
                c = path.split(os.sep)
                group_relative_path = c[-2] + "/" + c[-1]

                if target_name in LOCKBOX_TARGETS:
                    # Lockbox has translations checked into the repo
                    # first check to see if there is already a reference to that file
                    print path + "|||" + group_relative_path
                    if file_reference_exists(project, group_relative_path, variant_group):
                        continue

                file_reference = add_file_reference(project, group_relative_path, variant_group)

    project.save()
