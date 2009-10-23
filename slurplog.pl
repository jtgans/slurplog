#!/usr/bin/env perl

=head1 NAME

slurplog.pl - a simple script to pull down multiple log files

=head1 SYNOPSIS

slurplog.pl [-h] [-t] [-d date] <config_file>

See below for more description of the switches.

=head1 REQUIREMENTS

Slurplog currently requires the following Perl modules in order to
function:

    * XML::Simple
    * Net::FTP
    * Date::Manip
    * A working POSIX strftime implementation

All of these (save the strftime implementation) are available from
your friendly CPAN mirror.

=head1 DESCRIPTION

slurplog is a quick script that takes an XML configuration file as
input and downloads various log files from the settings in the
file. Primarily, slurplog uses Net::FTP as its method to download
files.

Slurplog was created for the need of downloading many log files from
varying servers with varying file names (usually based upon the date
and time). As such, filenames are run through strftime and converted
to their respective values.

=head1 OPTIONS

-h    Prints out a brief help message.

-t    Tests the configuration file for validity, and shows what it's
      internal configuration is using Data::Dumper.

-d date
      Run slurplog as if it was the day described by date. Note that
      date is either an absolute date or relative date in textual
      format, so you need to enclose date in double quotes to make it
      show up as one parameter. Example dates are "January 1st, 1970"
      or "3 days ago".

<config_file>
      The name of an XML configuration file, as described below.

=head1 CONFIGURATION FORMAT

Slurplog's configuration format is a simple XML file of the form:

    <config>
      <general>
        <baselogdir> ... </baselogdir>
        <template> ... </template>
      </general>

      <sites>
        <site>
          <host> ... </host>
          <port> ... </port>
          <user> ... </user>
          <pass> ... </pass>
          <passive> ... </passive>
          <logdir> ... </logdir>
          <logfile> ... </logfile>
          <cwd> ... </cwd>
        </site>

        <site> ... </site>
      </sites>
    </config>

All configuration files B<must> start with the <config> tag,
otherwise they're not valid configuration files.

=over 4

=item <general>

General, non-site specific configuration is place here. Currently,
only two tags are supported: <baselogdir> and <template>.

=item <baselogdir>

This tag sets the base directory where slurplog will store it's log
files.

=item <template> [optional]

<template> is a special case tag, and accepts all of the same tags
that the <site> tag does. This is primarily used for large setups
where you have multiple sites with similar settings and you want to
set a general template. See the example configuration for an idea of
how this works. This is I<not> required in the configuration.

=item <sites>

<sites> is a required tag, and defines a collection of <site>
tags. Without this tag, slurplog doesn't know what the heck to do.

=item <site>
This tag starts a definition for a website's log file. Alone, this
tag is meaningless, but with it's child tags, it becomes a powerful
tool for downloading the logfiles for each site.

=back

=head2 Tags Understood in <site> and <template>

Tags that are understood in the <site> and <template> sections are
below. Note that if a tag is present in the <template> section, it
becomes optional in the following <site> definitions. You can
override the <template>'s settings, however, by setting these tags in
the <site> definitions.

=over 4

=item <host>

The fully qualified domain name of the host to connect to.

=item <port> [optional]

The port number to connect to. Defaults to 21 if not specified.

=item <user>

The username to connect as.

=item <pass>

The plaintext password to connect with.

=item <passive> [optional]

Either 1 or 0 to turn on or off passive mode. Defaults to off if not
specified.

=item <logdir>

The name of the subdirectory to download the log files into. Note
that this is a subdirectory of <baselogdir>, so it should not have
any slashes in it.

=item <logfile>

The filename of the logfile to download, without a path. Note that
this is actually passed directly to strftime, and as such, you can
pass in any of strftime's format codes. For example, the filename
"access.%y%m%d.log" will expand to "access.<year><month><day>.log".

=item <cwd>

The directory of the logfile to download. Note that this is passed
verbatim to the CWD command for FTP, so it can be either an absolute
pathname or a relative one.

=back

=head1 EXAMPLE CONFIG FILE

    <config>
      <general>
        <baselogdir>/var/slurplog_downloads</baselogdir>

        <template>
          <host>example.com</host>
          <port>2121</port>
          <user>joe@blow.com</user>
          <pass>open123</pass>
          <passive>1</passive>
        </template>
      </general>

      <sites>
        <site>
          <logdir>foo_website</logdir>
          <cwd>/joes_website/logs</cwd>
          <logfile>access.%y%m%d.log</logfile>
        </site>

        <site>
          <logdir>bar_website</logdir>
          <cwd>/bar_website/logs</cwd>
          <logfile>access.log</logfile>
        </site>
      </sites>
    </config>

=head1 BUGS

* No known bugs at this time.

=head1 AUTHOR

June R. Tate <june@theonelab.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms  of the GNU General Public License as published
by the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNEESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details. 

You should have recieved a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA.

=cut

use strict;
use XML::Simple;
use Net::FTP;
use Date::Manip;
use Data::Dumper;
use POSIX "strftime";

my $CONFIG;
my $TIME;

sub loadConfig {
    my $configfile = shift;

    if (-e $configfile) {
        $CONFIG = XMLin($configfile, ForceArray => ["site"]);
    } else {
        die("*** $configfile not found.");
    }

    return 1;
}

sub mungeConfig {
    my @validSites;
    my %temp;
    my %site;

    print "Using date as ". localtime($TIME) ."\n";

    foreach (@{$CONFIG->{sites}->{site}}) {
        %site = %{$CONFIG->{general}->{template}};
        %temp = %{$_};

        foreach (keys(%temp)) {
            $site{$_} = $temp{$_};
        }

        if (!$site{logdir}) {
            print "No logdir associated with site. Skipping.";
            next;
        }

        if (!$site{logfile}) {
            print "No logfile associated with site. Skipping.";
            next;
        } else {
            $site{logfile} = strftime($site{logfile}, localtime($TIME));
        }

        push(@validSites, {%site});
    }

    $CONFIG->{sites}->{site} = \@validSites;
    return 1;
}

sub getLogs {
    my $ftp;

    foreach (@{$CONFIG->{sites}->{site}}) {
        print $_->{host} .": ";
        
        $ftp = Net::FTP->new($_->{host}, (Port => $_->{port}, Passive => $_->{passive}));
        if (!$ftp) {
            print "CONNECT FAIL.\n";
            print STDERR "Unable to establish connection with $_->{host}. Net::FTP reports: ". $@;
            print STDERR "Skipping $_->{host}...\n";
            next;
        } else {
            print "CONNECT ";
        }
            
        if (!$ftp->login($_->{user}, $_->{pass})) {
            print "LOGIN FAIL.\n";
            print STDERR "Unable to login to $_->{host} as $_->{user}. Net::FTP reports: ". $ftp->message;
            print STDERR "Skipping $_->{host}...\n";
            next;
        } else {
            print "LOGIN ";
        }

        if (!$ftp->cwd($_->{cwd})) {
            print "CWD FAIL.\n";
            print STDERR "Unable to CWD to $_->{cwd}. Net::FTP reports: ". $ftp->message;
            print STDERR "Skipping $_->{host}...\n";
            next;
        } else {
            print "CWD ";
        }

        chdir($_->{logdir});
        $ftp->ascii();
        if (!$ftp->get($_->{logfile})) {
            print "GET FAIL.\n";
            print STDERR "Unable to get $_->{logfile} from host $_->{host}. Net::FTP reports: ". $ftp->message;
            print STDERR "Skipping $_->{host}...\n";
            next;
        } else {
            print "GET (". $_->{logfile} .").\n";
        }
    }
}

sub checkLogDirs {
    if (!$CONFIG->{general}->{baselogdir}) {
        die("<baselogdir> is not defined in the configuration file.");
    }

    if (!-e $CONFIG->{general}->{baselogdir}) {
        die("The baselogdir ". $CONFIG->{general}->{baselogdir} ." doesn't exist.");
    }

    foreach (@{$CONFIG->{sites}->{site}}) {
        if (!-e $CONFIG->{general}->{baselogdir} ."/". $_->{logdir}) {
            if (!mkdir($CONFIG->{general}->{baselogdir} ."/". $_->{logdir}, 0755)) {
                die("Unable to make directory ". $CONFIG->{general}->{baselogdir} ."/". $_->{logdir});
            }
        }

        $_->{logdir} = $CONFIG->{general}->{baselogdir} ."/". $_->{logdir};
    }
}

sub dumpHelp {
    print <<EOF
Usage: slurplog [<options>] <configfile>

  Where <options> is one of the following:
    -t  Test the config file and dump it out to stdout.
    -d  Set the date (make sure you enclose the date in quotes)
    -h  Display this help
EOF
}

BEGIN {
    my $date;

    $TIME = time();
    
    if (scalar(@ARGV) == 0) {
        dumpHelp();
    }
    
    while ($_ = shift(@ARGV)) {
        if ($_ eq "-t") {
            loadConfig(shift(@ARGV));
            mungeConfig();
            print Dumper($CONFIG);
            
        } elsif ($_ eq "-h") {
            dumpHelp();
            
        } elsif ($_ eq "-d") {
            $date = ParseDate(shift(@ARGV));
            
            if (!$date) {
                print("Bad date passed.");
                exit(1);
            } else {
                $TIME = UnixDate($date, "%s");
            }
            
        } elsif (-e $_) {
            loadConfig($_);
            mungeConfig();
            checkLogDirs();
            getLogs();
            
        } else {
            dumpHelp();
        }
    }
}
