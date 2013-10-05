use v5.10;
use strict;
use warnings;

package HTTP::Tiny::UA;
# ABSTRACT: Higher-level UA features for HTTP::Tiny
# VERSION

use superclass 'HTTP::Tiny' => 0.036;

use HTTP::Tiny::UA::Response;

=method new|get|head|put|post|delete|post_form|mirror

These methods are inherited from L<HTTP::Tiny> and work the same way.

=method request

    my $res = HTTP::Tiny->new->get( $url );

Just like L<HTTP::Tiny::request|HTTP::Tiny/request>, but returns a
L<HTTP::Tiny::UA::Reponse> object.  Since all other C<get>, C<post>, etc.
methods eventually invoke this one so all methods will return response object
now.

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

=head1 CONTRIBUTING

Unlike L<HTTP::Tiny>, this module is open to additional features.  Please
discuss new ideas on the bug tracker for feedback before implementing.

While this module is not strictly "Tiny", here are some general guidelines:

=for :list
* The goal for this module is not feature/API equivalence with L<LWP::UserAgent>
* Core module dependencies and "::Tiny" module dependencies are OK
* Other CPAN modules should be used sparingly and only for good reasons
* Any XS dependencies must be optional

=head1 SEE ALSO

=for :list
* L<HTTP::Tiny> — the underlying client
* L<HTTP::Thin> — another HTTP::Tiny extension that uses L<HTTP::Message> objects
* L<LWP::UserAgent> — when you outgrow HTTP::Tiny, use this

=cut

# vim: ts=4 sts=4 sw=4 et:
