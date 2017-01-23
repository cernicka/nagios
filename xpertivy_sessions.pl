#!/usr/bin/env perl

# Nagios plugin to count and list the active sessions from Xpert.Ivy 3.9 Build
# 52 Patch 3, a web application. Used for ensuring the licensed count is not
# reached, so users won't be locked out.

# This script logs into the web console and loads the "Web Application
# Information" page. There is, among others, a list of "Running Sessions" in a
# table. Script counts the elements of this particular table row and prints it.

# Author: Martin Cernicka

use WWW::Mechanize;
use HTML::TableExtract;
use Nagios::Plugin;
use Nagios::Plugin::Threshold;

use warnings;
use strict;

# Nagios::Plugin object, used in multiple functions
our $NP;

# get the user sessions
# parameters: $NP - a Nagios::Plugin object
sub get_sessions {
	my $NP = shift;

	my $mech = WWW::Mechanize->new( autocheck => 0 );

	# an LWP response object
	my $res;

	# arbitrary URL to get the session started
	$res = $mech->get( $NP->opts->session_url );
	if ( $res->is_error ) {
		$NP->nagios_exit( UNKNOWN, $res->status_line );
	}

	# log in through submitting the form
	$res = $mech->submit_form(
		fields => { name => $NP->opts->username, pw => $NP->opts->password } );
	if ( $res->is_error ) {
		$NP->nagios_exit( UNKNOWN, $res->status_line );
	}

	# get the session list
	$res = $mech->get( $NP->opts->session_url );
	if ( $res->is_error ) {
		$NP->nagios_exit( UNKNOWN, $res->status_line );
	}

	my $te = HTML::TableExtract->new();
	$te->parse( $mech->content );

	# logout in order to not accumulate user sessions
	$res = $mech->get( $NP->opts->logout_url );
	if ( $res->is_error ) {
		$NP->nagios_exit( UNKNOWN, $res->status_line );
	}

	# search the table rows for 'Running Sessions' in the first column
	foreach my $table ( $te->tables ) {
		foreach my $row ( $table->rows ) {
			if ( defined( $row->[0] ) && $row->[0] eq "Running Sessions" ) {

		  # remove DOS newline characters, whitespace and empty lines
		  # TODO: why this doesn't work? $row->[1] =~ s/(?:\r|^\s+|^\s*\n)//gm;
				$row->[1] =~ s/\r//gm;
				$row->[1] =~ s/^\s+|^\n//gm;

				# count non-empty lines
				my $count = ( $row->[1] =~ tr/\n// );

				#print("Session count: $count, Session list:\n$row->[1]\n");
				$NP->add_perfdata(
					label => "Session count",
					value => $count
				);

				# return session count and session list
				$NP->nagios_exit( $NP->check_threshold($count), $row->[1] );
			}
		}
	}

	$NP->nagios_exit( UNKNOWN, "No table row 'Running Sessions' found!" );
	return;
}

sub main {
	$NP = Nagios::Plugin->new(
		plugin    => 'xpertivy_sessions',
		shortname => 'Xpert.Ivy Sessions',
		version   => '0.1',
		usage =>
		  "Usage: %s -H host -s <session_url> -l <logout_url> -u <username> -p <password> -w <sessions> -c <sessions>",
		blurb => "Returns the count and list of active Xpert.Ivy sessions."
	);

	$NP->add_arg(
		spec     => 'session_url|s=s',
		help     => '-s URL which lists the sessions',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'logout_url|l=s',
		help     => '-l URL which logs the user out',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'username|u=s',
		help     => '-u user name to log in with',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'password|p=s',
		help     => '-p password for logging in',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'warning|w=s',
		help     => '-w sessions',
		required => 1,
	);

	$NP->add_arg(
		spec     => 'critical|c=s',
		help     => '-c sessions',
		required => 1,
	);

	# analyze parameters
	$NP->getopts;

	# get the data
	get_sessions($NP);
}

main();

