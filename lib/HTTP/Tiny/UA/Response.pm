use strict;
use warnings;

package HTTP::Tiny::UA::Response;
# ABSTRACT: Wrap HTTP::Tiny response as objects with accessors

our $VERSION = '0.004';

use Class::Tiny qw( success url status reason content headers protocol );
use Encode qw();

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

=method content_type

Returns the L<< C<type/subtype>|http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7 >> portion of the C<content-type> header.

Returns C<undef> if there was no C<content-type> header.

    if ( $result->content_type eq 'application/json' ) {
        ...
    }

=cut

sub content_type {
    my ($self) = @_;
    return unless exists $self->headers->{'content-type'};
    return
      unless my ($type) =
      $self->headers->{'content-type'} =~ qr{ \A ( [^/]+ / [^;]+ ) }msx;
    return $type;
}

=method content_type_params

Returns all L<< C<parameter>|http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7 >> parts of the C<content-type> header
as an C<ArrayRef>.

Returns an empty C<ArrayRef> if no such parameters were sent in the C<content-type> header, or there was no C<content-type> header.

    for my $header ( @{ $result->content_type_params } ) {
        if ( $header =~ /^charset=(.+)/ ) {
            print "A charset of $1 was specified! :D";
        }
    }

=cut

sub content_type_params {
    my ($self) = @_;
    return [] unless exists $self->headers->{'content-type'};
    return []
      unless my (@params) = $self->headers->{'content-type'} =~ qr{ (?:;([^;]+))+ }msx;
    return [@params];
}

=method decoded_content

    ->decoded_content(\%opts);

Returns L<< C<< ->content >>|/content >> after applying type specific decoding.

At present, this means everything that is not C<text/*> will simply yield C<< ->content >>

And everything that is C<text/*> without a C<text/*;charset=someencoding> will simply yield C<< ->content >>

    my $foo = $result->decoded_content(); # text/* with a specified encoding interpreted properly.

Optionally, you can pass a default encoding to apply if none is specified:  and override smart detection.

    my $foo = $result->decoded_content({ encoding => 'utf-8' }); # utf8 assumed if none is specified

And, you can force an encoding to apply to override smart detection.

    my $foo = $result->decoded_content({ encoding => 'utf-8', force => 1 }); #  type specific encodings ignored, utf-8 forced.

By default, decoding is I<best effort>, using C<Encoding::FB_DEFAULT> to handle unusual cases.

This can be overridden:

    my $foo = $result->decoded_content({ encoding => 'utf-8', force => 1, fallback => Encoding::FB_CROAK }); # Bad utf8 == die

=cut

sub decoded_content {
    my ( $self, $opts ) = @_;

    $opts = {} unless $opts;

    my $encoding = $opts->{encoding};

    my $fallback = exists $opts->{fallback} ? $opts->{fallback} : Encode::FB_DEFAULT;

    encodingsniff: {
        last if $opts->{force};
        last if not my $type = $self->content_type;
        last unless $type =~ qr{ \Atext/ }msx;
        for my $param ( @{ $self->content_type_params } ) {
            if ( $param =~ qr{ \Acharset=(.+)\z }msx ) {
                $encoding = $1;
            }
        }
    }
    return $self->content if not defined $encoding;
    return Encode::decode( $encoding, $self->content, $fallback );
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
