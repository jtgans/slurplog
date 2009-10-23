Slurplog v0.2 -- Initial Release
Created by June Tate <june@theonelab.com>

Slurplog is a script that downloads multiple log files from
webservers, defined by an XML configuration file.

It was originally created to handle filenames that varied based upon
date and time, so as a result, it is dependent upon a working
strftime implementation. So far, Slurplog has been tested to work on
the following operating systems:

    - All Linux flavors
    - MacOS X
    - Free/OpenBSD

Microsoft-based systems may not work due to the strangeness in
handling strftime -- AFAIK, strftime isn't available as a POSIX
function on Windows machines. If anyone has any information
otherwise, I'd be happy to hear about it. =o)

In any case, most of the documentation is available in POD format in
the slurplog.pl file. In case you don't have access to perldoc
(heaven forbid), I've converted the documentation into plaintext
format in the file "perldoc.txt".

    -- June
