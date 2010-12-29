PatentSafe Stripper
===================

The PatentSafe Stripper is a small Ruby script that will create a copy of a
[PatentSafe][0] repository stripped of all sensitive data.


Usage Instructions
------------------

### Examples ###

    ruby psstrip.rb /path/to/repository /path/to/copy

A directory named `patentsafe-stripped` is created under the copy
directory. In the above example the copy would be created at
`/path/to/copy/patentsafe-stripped`

Other examples:

    ruby psstrip.rb -q /path/to/repository /path/to/copy
    ruby psstrip.rb --verbose /path/to/repository /path/to/copy
    ruby psstrip.rb -V /path/to/repository /path/to/copy

### Command Line Usage ###

    psstrip.rb [options] "/path/to/repository" "/path/to/copy"


For help use: `ruby pscheck.rb -h`

### Options: ###

    -h, --help    | Displays help message |
    -v, --version | Display the version, then exit |
    -q, --quiet   | Output as little as possible, overrides verbose |
    -V, --verbose | Verbose output |


Requirements
------------

The stripper requires Ruby 1.8 or later


License
-------

Copyright (c) 2010 Amphora Research Systems Ltd.

The script is made available under the GPL v3. If you improve this script for
your own purposes, we'd be delighted if you felt able to share your changes.


About this document
-------------------

This document is formatted in [Markdown](http://daringfireball.net/projects/markdown/)

[0]: http://www.amphora-research.com/products/patentsafe