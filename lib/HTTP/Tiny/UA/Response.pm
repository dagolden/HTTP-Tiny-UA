use strict;
use warnings;

package HTTP::Tiny::UA::Response;
# ABSTRACT: Wrap HTTP::Tiny response as objects with accessors

our $VERSION = '0.005';

# Declare custom accessor before Class::Tiny loads
use subs 'headers';

use Class::Tiny qw(
    success
    method
    url
    status
    reason
    content
    protocol
    headers
);

=attr success

=attr method

=attr url

=attr protocol

=attr status

=attr reason

=attr content

=attr headers

=method header

    $response->header( "Content-Length" );

Return a header out of the headers hash.  The field is case-insensitive.  If
the header was repeated, the value returned will be an array reference.
Otherwise it will be a scalar value.

=cut

# Don't return the original hash reference because the caller could
# alter that referred-to hash, which in turn would alter this object's
# internals, which we almost certainly do not want!
sub headers {
    my ($self) = @_;

    my $headers = $self->{headers};
    my %copy;

    while ( my ( $k, $v ) = each %$headers ) {
        $copy{$k} = ref($v) eq 'ARRAY' ? [@$v] : $v;
    }

    return \%copy;
}

sub header {
    my ( $self, $field ) = @_;

    # NB: lc() can potentially use non-English (e.g., Turkish)
    # lowercasing logic, which we very likely do not want here.
    $field =~ tr/A-Z/a-z/;

    # We don't return the original array reference for the same reason
    # why headers() doesn't return the original hash reference.
    my $hdr = $self->{headers}{$field};

    return ref($hdr) eq 'ARRAY' ? [@$hdr] : $hdr;
}

1;

=for Pod::Coverage BUILD

=head1 SYNOPSIS

    my $res = HTTP::Tiny->new->get( $url );

    if ( $res->success ) {
        say "Got " . $res->header("Content-Length") . " bytes";
    }

=head1 DESCRIPTION

This module wraps an L<HTTP::Tiny> response as an object to provide some
accessors and convenience methods.

=cut

# vim: ts=4 sts=4 sw=4 et:
