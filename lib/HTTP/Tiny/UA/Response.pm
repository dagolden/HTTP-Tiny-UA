use v5.10;
use strict;
use warnings;

package HTTP::Tiny::UA::Response;
# ABSTRACT: Wrap HTTP::Tiny response as objects with accessors
# VERSION

use Class::Tiny qw( success url status reason content headers protocol );

=attr success

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

sub header {
    my ( $self, $field ) = @_;
    return $self->headers->{ lc $field };
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
