#!/usr/bin/env python

import datetime
import glob
import os.path
import sys

if __name__ == "__main__":

    root = sys.argv[1]

    print '''
    <html>
    <head>
    <style>
    body {
    background-color: #e0e0e0;
    }
    .preview {
    margin: 20px;
    width: 20%;
    height: auto;
    }
    </style>
    </head>
    <body>
    '''



    print "<h1>Screenshots for %s</h1>" % root.split("/")[-1]
    print "<p><i>Updated on %s GMT</i></p>" % str(datetime.date.today())

    images = glob.glob("%s/*/*.png" % root)
    for image in images:
        path = "/".join(image.split("/")[-2:])
        print '<a href="%s">' % path
        print '  <img src="%s" class="preview"/>' % path
        print '</a>'

    print '''
    </body>
    </html>
    '''


