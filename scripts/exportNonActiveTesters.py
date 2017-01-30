# This will take the default outputted .csv from pilot's `export` command, 
# scan through it, and produce a space-separated list of user emails that
# have never installed a build of Firefox Beta. The output `nonActiveTesters.txt`
# file can then be used with pilot's `remove` command like so:
#
#       fastlane pilot remove `cat nonActiveTesters.txt`
#

import csv
with open("testers.csv", "rb") as testers:
    testerReader = csv.reader(testers, delimiter=",", quotechar="\"")
    out = open("nonActiveTesters.txt", "w")

    inactiveUserCount = 0
    for row in testerReader:
        if row[5] == "":
            inactiveUserCount += 1
            out.write("{0} ".format(row[2]))
    out.close()
    print("Exported {0} inactive users to nonActiveTesters.txt".format(inactiveUserCount))



