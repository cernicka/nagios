#!/usr/bin/env perl

# Martin.Cernicka@mm-karton.com
# This program tests the MM libraries. Feel free to add more tests.

# in order to stop the debugger at a line: $DB::single = 1;

use strict;
use warnings;
use English qw( -no_match_vars );

use Cwd qw(abs_path);
use File::Basename;
use POSIX;
use Config::Simple;

# set the library path to the program path
use lib dirname( abs_path($0) ) . '/../';

use Test::More;

# modules to test
use NagiosStatus;

sub main {
	ok( my $nagios = NagiosStatus->new(
			{   nagios_server  => 'nagios.your.company',
				nagios_host    => 'HOSTNAME_IN_NAGIOS',
				nagios_service => 'JOB_name_in_nagios'
			}
		),
		'NagiosStatus->new'
	);

	#note(explain($nagios));

	is( $nagios->send(
			status => 0,
			text   => 'Testing NagiosStatus::send'
		),
		1,
		'NagiosStatus->send'
	);

	done_testing();
}

main;

