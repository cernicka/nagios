package MMnagios_status;

# Author: Martin Cernicka
# Send status to Nagios using send_nsca.

# TODO:? improve for 'singleton', like in Log::Log4Perl

use strict;
use warnings;

# parameters: a hash_ref of following:
#       nagios_server
#       nagios_port (optional), default 5667
#		nsca: (optional) path to the nsca agent, default /usr/sbin/send_nsca
#		nagios_host: name of the device in Nagios
#		nagios_service: name of the Nagios service
# returns: 1 on success, undef otherwise
sub new {
	my ( $class, $arg ) = @_;
	my $nsca;

	# different defaults on SLES and Debian, so find out, where it is
	if ( !defined $arg->{nsca} ) {
		foreach my $f ( '/usr/sbin/send_nsca', '/usr/bin/send_nsca' ) {
			$nsca = $f if ( -x $f );
		}
	}

	# TODO:? only copy the 5 parameters described above, not all of %args
	my $self = {
		nagios_port => '5667',
		nsca        => $nsca,
		%{$arg}
	};

	bless( $self, $class );
	return $self;
}

# send a notification to a nagios server
# parameters:
#	arg{status}: 0 OK, 1 Warning, 2 Critical, 3 Unknown
#	arg{text}: message to be shown in Nagios. see further down for details
sub send {
	my ( $self, %arg ) = @_;
	my $FH;

	my @nsca_args = (
		'-H', $self->{nagios_server}, '-p', $self->{nagios_port},
		'-c', '/etc/send_nsca.cfg'
	);

	# if the text doesn't provide a full status line with values (separated
	# using '|', see Nagios plugin documentation), add a value named 'Status'
	my $text;

	if ( $arg{text} =~ /\|/ ) {
		$text = $arg{text};
	} else {

		# status code to text: array index [0, 1, 2, 3]
		my @status = ( 'OK', 'Warning', 'Critical', 'Unknown' );

		$text =
		  $status[ $arg{status} ]
		  . " - $arg{text} |'Status'=$arg{status};0;1;0;3";
	}

	# this is the complete nsca status line
	$text = "$self->{nagios_host}\t$self->{nagios_service}\t$arg{status}\t$text\n";

	# save and redirect STDOUT to /dev/null
	open( my $STD_OLD, '>&', STDOUT );
	if ( !open( STDOUT, '>', '/dev/null' ) ) {
		print( STDERR "Cannot redirect STDOUT: $!" . " at " . __FILE__ . ":"
			  . __LINE__ );
		return;
	}

	if ( !open( $FH, '|-', $self->{nsca}, @nsca_args ) ) {
		print(  STDERR "Cannot execute '"
			  . $self->{nsca} . "': $!" . " at "
			  . __FILE__ . ":"
			  . __LINE__ );
		return;
	}

	# send the status line to nagios
	print( $FH $text );

	if ( !close($FH) ) {
		print(  STDERR "Cannot send message to Nagios using '$self->{nsca}': $!" . " at " 
			  . __FILE__ . ":"
			  . __LINE__ );
		return;
	}

	if ( !open( STDOUT, '>&', $STD_OLD ) ) {
		print( STDERR "Cannot restore STDOUT: $!" . " at " . __FILE__ . ":"
			  . __LINE__ );
		return;
	}

	return (1);
}

1;

