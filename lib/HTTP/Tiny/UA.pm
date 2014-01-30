use v5.10;
use strict;
use warnings;
use utf8;

package HTTP::Tiny::UA;
# ABSTRACT: Higher-level UA features for HTTP::Tiny
# VERSION

use superclass 'HTTP::Tiny' => 0.036;
use File::Basename;
use Carp;
use MIME::Base64;
use Path::Tiny;

use HTTP::Tiny::UA::Response;

=method new

    $http = HTTP::Tiny::UA->new( %attributes );

This is inherited from L<HTTP::Tiny>.  The only difference so far is that
C<agent> will be C<HTTP-Tiny-UA/$VERSION>.

=for :list
* C<agent>
A user-agent string (defaults to 'HTTP-Tiny-UA/$VERSION'). If C<agent> ends in a space character, the default user-agent string is appended.
* C<cookie_jar>
An instance of L<HTTP::CookieJar> or equivalent class that supports the C<add> and C<cookie_header> methods
* C<default_headers>
A hashref of default headers to apply to requests
* C<local_address>
The local IP address to bind to
* C<max_redirect>
Maximum number of redirects allowed (defaults to 5)
* C<max_size>
Maximum response size (only when not using a data callback).  If defined,
responses larger than this will return an exception.
* C<proxy>
URL of a proxy server to use (default is C<$ENV{http_proxy}> if set)
* C<no_proxy>
List of domain suffixes that should not be proxied.  Must be a comma-separated string or an array reference. (default is C<$ENV{no_proxy}>)
* C<timeout>
Request timeout in seconds (default is 60)
* C<verify_SSL>
A boolean that indicates whether to validate the SSL certificate of an C<https>
connection (default is false)
* C<SSL_options>
A hashref of C<SSL_*> options to pass through to L<IO::Socket::SSL>

See L<SSL SUPPORT in HTTP::Tiny|HTTP::Tiny/SSL SUPPORT> for more on the
C<verify_SSL> and C<SSL_options> attributes.

=method get|head|put|post|post_form|mirror|delete

These methods are inherited from L<HTTP::Tiny> and work the same, except they
invoke the L<HTTP::Tiny::UA request|/request> method and return a
L<HTTP::Tiny::UA::Response> object.

=method request

    my $res = HTTP::Tiny->new->get( $url );

Just like L<HTTP::Tiny::request|HTTP::Tiny/request>, but returns a
L<HTTP::Tiny::UA::Reponse> object.  All other C<get>, C<post>, etc. methods
eventually invoke this one so all such methods return response objects now.

=cut

sub request {
    my ( $self, @args ) = @_;
    my $res = $self->SUPER::request(@args);
    return HTTP::Tiny::UA::Response->new($res);
}

=method post_multipart

    $response = $http->post_form($url, $form_data);
    $response = $http->post_form($url, $form_data, \%options);

=cut

sub post_multipart {
    my ( $self, $url, $data, $args ) = @_;

    ( @_ == 3 || @_ == 4 && ref $args eq 'HASH' )
      or Carp::croak( q/Usage: $http->post_multipart(URL, DATAREF, [HASHREF])/ . "\n" );

    ( ref $data eq 'HASH' || ref $data eq 'ARRAY' )
      or Carp::croak("form data must be a hash or array reference\n");

    my @params = ref $data eq 'HASH' ? %$data : @$data;
    @params % 2 == 0
      or Carp::croak("form data reference must have an even number of terms\n");

    my $headers = {};
    while ( my ( $key, $value ) = each %{ $args->{headers} || {} } ) {
        $headers->{ lc $key } = $value;
    }

    delete $args->{headers};

    my $content_parts = _build_content( \@params );
    my $boundary = _get_boundary( $headers, $content_parts );

    my $last_boundary = $boundary;
    substr $last_boundary, -2, 0, "--";

    return $self->request(
        'POST', $url,
        {
            %$args,
            content => $boundary . join( $boundary, @{$content_parts} ) . $last_boundary,
            headers => { %$headers, },
        }
    );
}

#--------------------------------------------------------------------------#
# MIME by hand by Renee Bäcker
#--------------------------------------------------------------------------#

sub _get_boundary {
    my ( $headers, $content ) = @_;

    # Generate and check boundary
    my $boundary;
    my $size = 1;

    while (1) {
        $boundary = encode_base64 join( '', map chr( rand 256 ), 1 .. $size++ * 3 );
        $boundary =~ s/\W/X/g;
        last unless grep { $_ =~ m{$boundary} } @{$content};
    }

    # Add boundary to Content-Type header
    ( $headers->{'content-type'} || '' ) =~ m!^(.*multipart/[^;]+)(.*)$!;

    my $before = $1 || 'multipart/form-data';
    my $after  = $2 || '';

    $headers->{'content-type'} = "$before; boundary=\"$boundary$after\"";

    return "--$boundary\x0d\x0a";
}

sub _build_term {
    my ( $key, $value, $more_disposition, $more_headers ) = @_;
    $more_disposition ||= [];
    $more_headers     ||= [];

    # Assemble content-disposition header
    my $cd = "Content-Disposition: form-data; name=\"$key\"";
    while (@$more_disposition) {
        my ( $k, $v ) = splice @$more_disposition, 0, 2;
        $cd .= "; $k=\"$v\"";
    }

    # Assemble rest of header
    my @lines = $cd;
    while (@$more_headers) {
        my ( $k, $v ) = splice @$more_headers, 0, 2;
        push @lines, "$k: $v";
    }

    return join( "\x0d\x0a", @lines ) . "\x0d\x0a\x0d\x0a$value\x0d\x0a";
}

sub _build_content {
    my ($params) = @_;

    my @terms;
    while (@$params) {
        my ( $key, $value ) = splice( @$params, 0, 2 );
        # ARRAY indicates file upload
        if ( ref $value eq 'ARRAY' ) {
            my ( $path, $name, @headers ) = @$value;
            $path = path($path);
            my $content = $path->slurp_raw;
            $content =~ s/\x0d?\x0a/\x0d\x0a/mg;
            push @terms,
              _build_term(
                $key, $content,
                [ 'filename',     $path->basename ],
                [ 'Content-Type', 'text/plain' ]
              );
        }
        else {
            push @terms, _build_term( $key, $value );
        }
    }

    return \@terms;
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

=head1 EXCEPTIONS

Exceptions from C<max_size>, C<timeout> or other error conditions will result
in a pseudo-HTTP status code of 599 and a reason of "Internal Exception". The
content field in the response will contain the text of the exception.

=head1 CONTRIBUTING

Unlike L<HTTP::Tiny>, this module is open to additional features.  Please
discuss new ideas on the bug tracker for feedback before implementing.

While this module is not strictly "Tiny", here are some general guidelines:

=for :list
* The goal for this module is B<not> feature/API equivalence with L<LWP::UserAgent>
* Core module dependencies and "Tiny"-ish module dependencies are OK
* Other CPAN modules should be used sparingly and only for good reasons
* Any XS dependencies must be optional

=head1 SEE ALSO

=for :list
* L<HTTP::Tiny> — the underlying client
* L<HTTP::Thin> — another HTTP::Tiny extension that uses L<HTTP::Message> objects
* L<LWP::UserAgent> — when you outgrow HTTP::Tiny, use this

=cut

# vim: ts=4 sts=4 sw=4 et:
