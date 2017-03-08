#!/usr/bin/env perl

use strict;
use warnings;

# Author: Martin Cernicka
# Runs the Nagios check_nrpe v2 and converts its output to PRTG XML on stdout.

# Needs to be converted to EXE (PAR::Packer), as Windows and PRTG in their
# united dumbness can't execute Perl scripts directly.

# TODO: Some more error handling? Could interfere with the normal output,
# though.

our $PROG =
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

# print help?
if ( $#ARGV eq 0 || $ARGV[0] eq '-h' ) {
	print(
		q{Usage: check_nrpe.pl <arg1> <...>

Alternative usage - execute a Nagios plugin installed locally:
check_nrpe.pl -E <path/plugin.exe> <arg1> <...>
}
	);
	exit 1;
}

# local plugin specified? take it instead of check_nrpe
if ( $ARGV[0] eq '-E' ) {
	shift(@ARGV);
	$PROG = shift(@ARGV);
}

# PRTG header
print( '<?xml version="1.0" encoding="UTF-8" ?><prtg>' . "\n" );

# execute the check_nrpe.exe
if ( !open( $PH, "-|", $PROG, @ARGV ) ) {
	printerr("Cannot start check_nrpe.exe: $!");
}

# read one line, not more (nrpe version 2 API)
chomp( $line = <$PH> );
close($PH);

if ( !defined($line) || $line eq "" ) {
	printerr("No output from check_nrpe.");
}

# NRPE status format:
# DISK OK| /=4276MB;4958;5233;0;5509 /home=534MB;877;926;0;975 /var=239MB;1755;1853;0;1951
( $status, $rest ) = split( '\|', $line );
if ( !defined($rest) ) {

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
	#while ( $rest ne '' || $channel ne '' ) {
	while ( $rest =~ s/(.*?)=([0-9.,-]*)[^ ]* *// ) {

		#( $channel, $value ) = $rest =~ /(.*?)=([0-9.,-]*)[^ ]* */;
		# cut the processed value out of the $rest (same regexp)

		( $channel, $value ) = ( $1, $2 );

		last if ( !defined($channel) );
		$value = '' if ( !defined($value) );

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

