#!/usr/bin/env perl

# Author: Martin Cernicka
# Nagios plugin: check_directory.pl - see help for details.

use POSIX;
use strict;
use warnings;

use Nagios::Plugin;
use Nagios::Plugin::Threshold;

# Nagios::Plugin object, used in multiple functions
our $NP;

# count files in a directory, find out age of newest or oldest file
# parameters: none
# global variable: $NP - a Nagios::Plugin object
# returns: $count or $age, but it never returns, calls $NP->nagios_exit
sub dir_info {
	my $dh;
	my $path;
	my $file_to_report;

	my $count = 0;
	my $mtime;

	( $count, $mtime, $file_to_report ) =
	  countfiles( $NP->opts->dir_name, $NP->opts->check,
		$NP->opts->recursive );

	if ( !defined($count) ) {
		$NP->nagios_die(
			"Error getting informations about '$file_to_report': $!\n");
	}

	# return the correct variable according to the parameters,
	# but always set the 'File count'
	$NP->add_perfdata(
		label => "File count",
		value => $count
	);

	if ( $NP->opts->check eq 'file_count' ) {
		$NP->nagios_exit( return_code => $NP->check_threshold($count), );
	}

	if ( $NP->opts->check eq 'age_newest' ) {
		$NP->add_perfdata(
			label => "Age of newest file \"$file_to_report\"",
			value => time - $mtime
		);

		$NP->nagios_exit( return_code => $NP->check_threshold( time - $mtime ),
		);
	}

	if ( $NP->opts->check eq 'age_oldest' ) {
		$NP->add_perfdata(
			label => "Age of oldest file \"$file_to_report\"",
			value => time - $mtime
		);

		$NP->nagios_exit( return_code => $NP->check_threshold( time - $mtime ),
		);
	}
}

# parameters:
#	dir_name: directory to check
#	check: "age_oldest" or "age_newest"
#	recursive: if !defined, don't descend into subdirectories
# returns: a list
#	count, timestamp oldest/newest, file_to_report
#		if everything goes well
#	undef, undef, file_to_report
#		in case of an error
sub countfiles {
	my ( $dir_name, $check, $recursive ) = @_;

	my $dh;
	my $path;
	my $file_to_report;

	my $count = 0;
	my $count2;
	my $oldest = time;
	my $newest = 0;
	my ( $mode, $mtime );

	opendir( $dh, $dir_name ) or do {
		return ( undef, undef, $dir_name );
	};

	while ( my $filename = readdir($dh) ) {
		$path = File::Spec->catpath( undef, $dir_name, $filename );

		# skip . and ..
		next if ( $filename =~ /^\.$|^\.\.$/ );

		# also counts directories
		$count++;
		if ( $check eq 'file_count' ) {

			# skip the rest of the work
			next;
		}

		# only do a stat() if the file age has been requested
		( $mode, $mtime ) = ( stat($path) )[ 2, 9 ];
		if ( !defined($mtime) ) {
			return ( undef, undef, $path );
		}

		# dive into subdirectories
		if ( defined($recursive) && POSIX::S_ISDIR($mode) ) {
			( $count2, $mtime, $path ) =
			  countfiles( $path, $check, $recursive );

			if ( !defined($count2) ) {
				return ( undef, undef, $path );
			}

			# all files from the subdirectory
			$count += $count2;
		}

		if ( $check eq 'age_newest' ) {

			# is it a new record?
			if ( $mtime > $newest ) {
				$newest         = $mtime;
				$file_to_report = $path;
			}
		}
		elsif ( $check eq 'age_oldest' ) {

			# is it a new record?
			if ( $mtime < $oldest ) {
				$oldest         = $mtime;
				$file_to_report = $path;
			}
		}
	}

	closedir($dh);

	if ( $check eq 'age_newest' ) {
		return ( $count, $newest, $file_to_report );
	}
	elsif ( $check eq 'age_oldest' ) {
		return ( $count, $oldest, $file_to_report );
	}
	else {
		return ( $count, undef, undef );
	}
}

sub main {
	$NP = Nagios::Plugin->new(
		plugin    => 'check_directory',
		shortname => 'Directory check',
		version   => '0.2',
		usage =>
		  "Usage: %s -C <check_type> -d <directory_name> -w <seconds> -c <seconds>",
		blurb =>
		  "This Nagios plugin checks the count of files in a directory,\nor the age of the newest or oldest file."
	);

	$NP->add_arg(
		spec     => 'check|C=s',
		help     => '-C <file_count|age_newest|age_oldest>',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'dir_name|d=s',
		help     => '-d directory_name',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'warning|w=s',
		help     => '-w seconds',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'critical|c=s',
		help     => '-c seconds',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'recursive|r',
		help     => '-r recursively search subdirectories',
		required => 0,
	);

	# analyze parameters
	$NP->getopts;

	# get the data
	dir_info;
}

main();
