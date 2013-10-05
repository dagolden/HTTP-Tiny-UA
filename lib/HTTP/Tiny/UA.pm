use v5.10;
use strict;
use warnings;

package HTTP::Tiny::UA;
# ABSTRACT: Higher-level UA features for HTTP::Tiny
# VERSION

use superclass 'HTTP::Tiny' => 0.036;

use HTTP::Tiny::UA::Response;

=method request

    my $res = HTTP::Tiny->new->get( $url );

Just like L<HTTP::Tiny::response|HTTP::Tiny/response>, but returns
a L<HTTP::Tiny::UA::Reponse object>.

=cut

sub request {
    my ( $self, @args ) = @_;
    my $res = $self->SUPER::request(@args);
    return HTTP::Tiny::UA::Response->new($res);
}

1;

=for Pod::Coverage BUILD

=head1 SYNOPSIS

    use HTTP::Tiny::UA;
    
    my $ua = HTTP::Tiny::UA->new(
        ...
    );

=head1 DESCRIPTION

This module extends L<HTTP::Tiny> with higher-level convenience features.

=head1 SEE ALSO

=for :list
* L<HTTP::Tiny> — the underlying client
* L<HTTP::Thin> — another HTTP::Tiny extension that uses L<HTTP::Message> objects
* L<LWP::UserAgent> — when you outgrow HTTP::Tiny, use this

=cut

# vim: ts=4 sts=4 sw=4 et:
