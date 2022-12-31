#!/usr/bin/env perl

#
# Copyright (C) 2021-2022 Joelle Maslak
# All Rights Reserved - See License
#

# PODNAME: router-colorizer.pl
# ABSTRACT: Colorize router CLI output

use v5.22;
use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use App::RouterColorizer;

my $TIMER = 0.01;    # Delay to wait for more data, in secs.

MAIN: {
    my $colorizer = App::RouterColorizer->new();

    STDOUT->autoflush(1);
    STDIN->blocking(0);

    my $buffer = '';
    my $rin    = '';
    vec( $rin, fileno(STDIN), 1 ) = 1;
    while (1) {
        select( my $rout = $rin, undef, my $eout = $rin, $TIMER );
        if ( vec( $rout, fileno(STDIN), 1 ) || vec( $eout, fileno(STDIN), 1 ) ) {
            # We have characters to potentially read
            my $tmp = '';
            read STDIN, $tmp, 65535, 0;
            if ( length($tmp) ) {
                $buffer .= $tmp;

                # We want to process complete lines only, without a
                # timeout.
                my ( $process, $newbuf ) = $buffer =~ m/^ (.*) (\n .*) $/sxx;
                $buffer = $newbuf // $buffer;

                if ( defined($process) ) {
                    print $colorizer->format_text($process);
                } elsif ( length($buffer) == 1 ) {
                    # One exception to processing complete lines is
                    # single character buffers - for these, we want to
                    # output the single character quickly to not cause
                    # lag in interactive sessions.
                    print $colorizer->format_text($buffer);
                    $buffer = '';
                }
            } else {
                # End of file
                print $colorizer->format_text($buffer) unless $buffer eq '';
                exit;
            }
        } else {
            # Timeout!
            if ( $buffer ne "" ) {
                print $colorizer->format_text($buffer);
                $buffer = "";
            }
        }
    }
}

__END__

=pod
=head1 SYNOPSIS

  /usr/bin/ssh router.example.com | router-colorizer.pl

=head1 DESCRIPTION

This script colorizes the output of router output, using
the L<App::RouterColorizer> module.  This script takes no arguments.

The output will be colorized based on detection of key strings as they
might be sent from Arista, Juniper, and VyOS routers.  It may also work
on other router outputs, but these have not been used for development.

=head1 COLOR CODING

Color coding is used, which assumes a black background on your terminal.
The colors used indicate different kinds of output. Note that most lines
of output are not colorized, only "important" (as defined by me!) lines
are colorized.

=over 4

=item C<green>

Green text is used to signify "good" values. For instance, in the output
from C<show interfaces> on an Arista router, seeing lines indicating the
circuit is "up" and not showing errors will show in green.

=item C<orange>

Orange text is used to show things that aren't "good" but also aren't "bad."
For instance, administratively down interfaces in C<show interfaces status>
will typically show as orange.

=item C<red>

Red text indicates error conditions, such as errors being seen on the
output of C<show interfaces>.

=item C<cyan>

Cyan text indicates potentially important text, seperated out from text
that is not-so-important.  For instance, in C<show bgp neighbors>, cyan
is used to point out lines indicating which route map is being used.

=back

=head1 IP Address Colorization

IP addresses are also colorized.  These are colorized one of several colors,
all with a colorized background, based on the IP/CIDR address.  Thus, an
IP address like C<1.2.3.4> will always be the same color, which should make
it easier to spot potential transposition or copy mistakes (if it shows up
sometimes as white-on-blue, but other times as black-on-red, it's not the
same address!).

=head1 Number Grouping/Underlines

The progarm also underlines alternating groups of 3 digits as they appear
in digit strings.  This is used to assist people who might have dyslexia
or other visual processing differences, to allow them to quickly determine
if 1000000 is 1,000,000 or 10,000,000.

=head1 Configuring a BASH Function

One way to make using this script easier is to create a Bash subroutine.
For instance, to use something like C<sshr routername.example.com> to
SSH to a router and filter the output through this script, define the
following in your C<~/.bashrc>:

    sshr() {
        ssh "$@" | router-colorizer.pl
    }

=head1 BUGS

None known, however it is certainly possible that I am less than perfect. If
you find any bug you believe has security implications, I would greatly
appreciate being notified via email sent to C<jmaslak@antelope.net> prior
to public disclosure. In the event of such notification, I will attempt to
work with you to develop a plan for fixing the bug.

All other bugs can be reported via email to C<jmaslak@antelope.net> or by
using the GitHub issue tracker
at L<https://github.com/jmaslak/App-RouterColorizer/issues>

=cut

