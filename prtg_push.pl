#!/usr/bin/env perl

use LWP::UserAgent;
use URI::Escape;
use warnings;
use strict;

# Author: Martin Cernicka
# TODO: convert send_http_push into a module like MMnagios_status.pm

# sends a status message to a PRTG server
#	https://www.paessler.com/manuals/prtg/http_push_data_advanced_sensor
# parameters: a hash of following:
#	server
#	port
#	sensor: sensor identification token
#	status: undef, error, warning (case sensitive)
#	channel: name of the channel
#	value: value of the named channel
#	text: message text for the channel
# returns: 1 on success, 0 otherwise
sub send_http_push {
	my %arg = @_;

	# XML data to be sent to PRTG
	my $xml;

	# set a status line, if told so
	if ( defined( $arg{'status'} ) && ( $arg{status} eq 'error' ) ) {
		$xml = "<prtg><error>1</error><text>$arg{text}</text></prtg>";
	} else {
		$xml =
		  "<prtg><result><channel>$arg{channel}</channel><value>$arg{value}</value>";

		if ( defined( $arg{'status'} ) && ( $arg{status} eq 'warning' ) ) {
			$xml .= '<warning>1</warning>' if ( $arg{status} eq 'warning' );
		}

		$xml .= "</result><text>$arg{text}</text></prtg>";
	}

	print("DEBUG: $xml\n");
	my $ua = LWP::UserAgent->new;

	my $res =
	  $ua->get( "http://$arg{server}:$arg{port}/$arg{sensor}?content="
		  . uri_escape_utf8($xml) );

	if ( !defined($res) || $res->status_line !~ /200 OK/ ) {
		print(  STDERR 'PRTG ERROR: Could not send a request to '
			  . "$arg{server}:$arg{port}!\n"
			  . ( defined($res) ? $res->status_line . "\n" : '' ) );
		return 0;
	}

	# check if the sensor has been reached
	if (   $res->content !~ /"status": "Ok"/
		|| $res->content =~ /"Matching Sensors": "0"/ )
	{
		print( {*STDERR} "PRTG ERROR: No matching sensor \"$arg{sensor}\": "
			  . "$res->content\n" );
		return 0;
	} else {
		return 1;
	}
}

# main()
# check the sensor status:
print(
	send_http_push(
		server  => 'srv-ha-prtg21.mmk.mmdom.net',
		port    => '5050',
		sensor  => '4EC62FC2-FBA9-4FE2-9135-AA329F622453',
		status  => 'warning',
		channel => 'Test3',
		value   => 114,
		text    => $0,
	  )
	  . "\n"
);

