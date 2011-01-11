PatentSafe Stripper
===================

The PatentSafe Stripper is a small Ruby script that will create a copy of a
[PatentSafe][0] repository stripped of all sensitive data.


Details
--------

The PatentSafe Stripper is a ruby script that 'strips' potentially sensitive
data from a PatentSafe repository. It creates a copy of the source repository
that is suitable to load by a PatentSafe server for testing and analysis.

When run against a PatentSafe repository, this script uses some basic rules
to decide what should happen to the files. A file may be:

* copied exactly as it is

* stripped of _specific_ content

* stripped of _all_ contents - effectively replaced

* skipped - not copied to the target

### What is removed? ###

Documents are stripped of data like the summary, _document_ text/content, and
metadata. The rest of the repository contents have usernames, groups and emails
addresses replaced.

### Users and Groups ###

The target (stripped) repository has most of the users and groups aliased to
anonymous names such as `User 1`, `User 2` and `Group 1`. The built in
`installer` account and `Admin` group are preserved. All user passwords are
reset to `password`.


Usage Instructions
------------------

### Examples ###

    ruby psstrip.rb source target

    ruby psstrip.rb /path/to/repository /path/to/copy

* source is a PatentSafe directory

* target is directory where stripped copy will be made. It is created
if it doesn't exist. If it exists and is non-empty you'll need to
pass the -f (--force) option.


Other examples:

    ruby psstrip.rb -f -q /path/to/repository /path/to/copy
    ruby psstrip.rb -q /path/to/repository /path/to/copy
    ruby psstrip.rb --verbose /path/to/repository /path/to/copy
    ruby psstrip.rb -V /path/to/repository /path/to/copy

### Command Line Usage ###

    psstrip.rb [options] "/path/to/repository" "/path/to/copy"


For help use: `ruby pscheck.rb -h`

### Options: ###
    -f, --force     Force copy to non-empty directory
    -h, --help      Displays help message
    -v, --version   Display the version, then exit
    -q, --quiet     Output as little as possible, overrides verbose
    -V, --verbose   Verbose output


Requirements
------------

Ruby 1.8 or later


License
-------

Copyright (c) 2010 Amphora Research Systems Ltd.

The script is made available under the GPL v3. If you improve this script for
your own purposes, we'd be delighted if you felt able to share your changes.


About this document
-------------------

This document is formatted in [Markdown](http://daringfireball.net/projects/markdown/)

[0]: http://www.amphora-research.com/products/patentsafe