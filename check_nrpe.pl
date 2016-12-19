#!/usr/bin/env perl

use strict;
use warnings;

# Author: Martin Cernicka
# Runs the Nagios check_nrpe v2 and converts its output to PRTG XML on stdout.

# Needs to be converted to EXE (PAR::Packer), as neither Windows, nor PRTG can execute
# Perl scripts directly.

# You will also need the check_nrpe.exe, compiled using Cygwin, and the
# libraries, including OpenSSL.

# TODO: include the script in a cmd: https://stackoverflow.com/questions/705851/how-do-i-create-drag-and-drop-strawberry-perl-programs
#    @SETLOCAL ENABLEEXTENSIONS
#    @c:\path\to\perl.exe -x "%~f0" %*
#    @exit /b %ERRORLEVEL%
#    #!perl
#    #line 6
#    # ...perl script continues here...

# Usage: check_nrpe.pl <arg1> <...>
my $NRPE =
  "C:/Program Files (x86)/PRTG Network Monitor/Custom Sensors/EXEXML/check_nrpe.exe";

# prints an error message and exits
# argument: text_to_print
sub printerr {
	print( "<error>1</error><text>" . shift . "</text></prtg>\n" );
	exit(1);
}

# main()
my $line;       # whole line from STDIN
my $status;     # Nagios status. unused.
my $rest;       # the rest of the line after status
my $channel;    # channel name
my $value;      # channel value

my $PH;

# PRTG header
print( '<?xml version="1.0" encoding="UTF-8" ?><prtg>' . "\n" );

# execute the check_nrpe.exe
if ( !open( $PH, "-|", $NRPE, @ARGV ) ) {
	printerr("Cannot start check_nrpe.exe: $!");
}

# read one line, not more (nrpe version 2 API)
chomp( $line = <$PH> );
close($PH);

if ( !defined $line || $line eq "" ) {
	printerr("No output from check_nrpe.");
}

# NRPE status format:
# DISK OK| /=4276MB;4958;5233;0;5509 /home=534MB;877;926;0;975 /var=239MB;1755;1853;0;1951
( $status, $rest ) = split( '\|', $line );
if ( !defined $rest ) {

	# here we got no status information
	# check if there is an "OK:" somewhere anyway
	if ( $line =~ /\bOK\b/ ) {
		print("<result><channel>$line</channel><value></value></result>\n");
	} else {

		# print the whole line in case any error messages show up
		printerr($line);
	}
} else {

	# get the channels and print them out
	# cannot just split(' ') them, because channel names can contain spaces
	# cut the processed value out of $rest while matching
	#TODO: document the regex using s///xms
	while ( $rest =~ s/(.*?)=([0-9.,-]*)[^ ]* *// ) {
		( $channel, $value ) = ( $1, $2 );

		last if ( !defined $channel );
		$value = '' if ( !defined $value );

		print("<result><channel>$channel</channel><value>$value</value>");

		# check for any other troubles. we cannot return an error, as
		# PRTG (stupid!) throws away any data in that case
		if ( $status =~ /\b(WARNING|CRITICAL)\b/ ) {
			print("<warning>1</warning>");
		}

		print("</result>\n");
	}
}

# print the status line in addition to the channel data. might be of interest.
print("<text>$status</text></prtg>\n");

