package TestUtils;

use strict;
use warnings;

use File::Basename;
use IO::File qw(SEEK_SET SEEK_END);
use IO::Dir;
use Test::More;

BEGIN {
    our @EXPORT_OK = qw(
      rewind
      tmpfile
      dir_list
      slurp
      parse_case
      hashify
      sort_headers
      connect_args
      clear_socket_source
      set_socket_source
      monkey_patch
      iterate_cases
      $CRLF
      $LF
    );

    require Exporter;
    *import = \&Exporter::import;
}

our $CRLF = "\x0D\x0A";
our $LF   = "\x0A";

sub rewind(*) {
    seek( $_[0], 0, SEEK_SET )
      || die(qq/Couldn't rewind file handle: '$!'/);
}

sub tmpfile {
    my $fh = IO::File->new_tmpfile
      || die(qq/Couldn't create a new temporary file: '$!'/);

    binmode($fh)
      || die(qq/Couldn't binmode temporary file handle: '$!'/);

    if (@_) {
        print( {$fh} @_ )
          || die(qq/Couldn't write to temporary file handle: '$!'/);

        seek( $fh, 0, SEEK_SET )
          || die(qq/Couldn't rewind temporary file handle: '$!'/);
    }

    return $fh;
}

sub dir_list {
    my ( $dir, $filter ) = @_;
    $filter ||= qr/./;
    my $d = IO::Dir->new($dir)
      or return;
    return map { "$dir/$_" } sort grep { /$filter/ } grep { /^[^.]/ } $d->read;
}

sub slurp (*) {
    my ($fh) = @_;

    seek( $fh, 0, SEEK_END )
      || die(qq/Couldn't navigate to EOF on file handle: '$!'/);

    my $exp = tell($fh);

    rewind($fh);

    binmode($fh)
      || die(qq/Couldn't binmode file handle: '$!'/);

    my $buf = do { local $/; <$fh> };
    my $got = length $buf;

    ( $exp == $got )
      || die(qq[I/O read mismatch (expexted: $exp got: $got)]);

    return $buf;
}

sub parse_case {
    my ($case) = @_;
    my %args;
    my $key = '';
    for my $line ( split "\n", $case ) {
        chomp $line;
        if ( substr( $line, 0, 1 ) eq q{ } ) {
            $line =~ s/^\s+//;
            push @{ $args{$key} }, $line;
        }
        else {
            $key = $line;
        }
    }
    return \%args;
}

sub hashify {
    my ($lines) = @_;
    return unless $lines;
    my %hash;
    for my $line (@$lines) {
        my ( $k, $v ) = ( $line =~ m{^([^:]+): (.*)$}g );
        $hash{$k} = [ $hash{$k} ] if exists $hash{$k} && ref $hash{$k} ne 'ARRAY';
        if ( ref( $hash{$k} ) eq 'ARRAY' ) {
            push @{ $hash{$k} }, $v;
        }
        else {
            $hash{$k} = $v;
        }
    }
    return %hash;
}

sub sort_headers {
    my ($text) = shift;
    my @lines = split /$CRLF/, $text;
    my $request = shift(@lines) || '';
    my @headers;
    while ( my $line = shift @lines ) {
        last unless length $line;
        push @headers, $line;
    }
    @headers = sort @headers;
    return join( $CRLF, $request, @headers, '', @lines );
}

{
    my ( @req_fh, @res_fh, $monkey_host, $monkey_port );

    sub clear_socket_source {
        @req_fh = ();
        @res_fh = ();
    }

    sub set_socket_source {
        my ( $req_fh, $res_fh ) = @_;
        push @req_fh, $req_fh;
        push @res_fh, $res_fh;
    }

    sub connect_args { return ( $monkey_host, $monkey_port ) }

    sub monkey_patch {
        no warnings qw/redefine once/;
        *HTTP::Tiny::Handle::can_read  = sub { 1 };
        *HTTP::Tiny::Handle::can_write = sub { 1 };
        *HTTP::Tiny::Handle::connect   = sub {
            my ( $self, $scheme, $host, $port ) = @_;
            $self->{host} = $monkey_host = $host;
            $self->{port} = $monkey_port = $port;
            $self->{fh}   = shift @req_fh;
            return $self;
        };
        my $original_write_request = \&HTTP::Tiny::Handle::write_request;
        *HTTP::Tiny::Handle::write_request = sub {
            my ( $self, $request ) = @_;
            $original_write_request->( $self, $request );
            $self->{fh} = shift @res_fh;
        };
        *HTTP::Tiny::Handle::close = sub { 1 }; # don't close our temps

        delete $ENV{http_proxy};                # don't try to proxy in mock-mode
    }
}

sub iterate_cases {
    my ( $ua_class, $dir, $selector ) = @_;

    for my $file ( dir_list( "t/cases", qr/^get/ ) ) {
        my $label = basename($file);
        my $data = do { local ( @ARGV, $/ ) = $file; <> };
        my ( $params, $expect_req, $give_res ) = split /--+\n/, $data;
        my $case = parse_case($params);

        my $url      = $case->{url}[0];
        my %headers  = hashify( $case->{headers} );
        my %new_args = hashify( $case->{new_args} );

        my %options;
        $options{headers} = \%headers if %headers;
        if ( $case->{data_cb} ) {
            $main::data = '';
            $options{data_callback} = eval join "\n", @{ $case->{data_cb} };
            die unless ref( $options{data_callback} ) eq 'CODE';
        }

        my $version = $ua_class->VERSION || 0;
        ( my $dashed_ua = $ua_class ) =~ s/::/-/g;
        my $agent = $new_args{agent} || "$dashed_ua/$version";

        # cleanup source data
        $expect_req =~ s{HTTP-Tiny/VERSION}{$agent};
        s{\n}{$CRLF}g for ( $expect_req, $give_res );

        # setup mocking and test
        my $res_fh = tmpfile($give_res);
        my $req_fh = tmpfile();

        my $http = $ua_class->new( keep_alive => 0, %new_args );
        set_socket_source( $req_fh, $res_fh );

        ( my $url_basename = $url ) =~ s{.*/}{};

        my @call_args = %options ? ( $url, \%options ) : ($url);
        my $response = $http->get(@call_args);

        my ( $got_host, $got_port ) = connect_args();
        my ( $exp_host, $exp_port ) =
          ( ( $new_args{proxy} || $url ) =~ m{^http://([^:/]+?):?(\d*)/}g );
        $exp_host ||= 'localhost';
        $exp_port ||= 80;

        my $got_req = slurp($req_fh);

        is( $got_host,              $exp_host,                 "$label host $exp_host" );
        is( $got_port,              $exp_port,                 "$label port $exp_port" );
        is( sort_headers($got_req), sort_headers($expect_req), "$label request data" );

        my ($rc) = $give_res =~ m{\S+\s+(\d+)}g;
        # maybe override
        $rc = $case->{expected_rc}[0] if defined $case->{expected_rc};

        is( $response->status, $rc, "$label response code $rc" )
          or diag $response->content;

        if ( substr( $rc, 0, 1 ) eq '2' ) {
            ok( $response->success, "$label success flag true" );
        }
        else {
            ok( !$response->success, "$label success flag false" );
        }

        is( $response->url, $url, "$label response URL" );
        is(
            $response->header("Content-Length"),
            $response->{headers}{'content-length'},
            "$label response Content-Length"
        );

        if ( defined $case->{expected_headers} ) {
            my %expected = hashify( $case->{expected_headers} );
            is_deeply( $response->headers, \%expected, "$label expected headers" );
        }

        my $check_expected = $case->{expected_like}
          ? sub {
            my ( $text, $msg ) = @_;
            like( $text, "/" . $case->{expected_like}[0] . "/", $msg );
          }
          : sub {
            my ( $text, $msg ) = @_;
            my $exp_content =
              $case->{expected} ? join( "$CRLF", @{ $case->{expected} }, '' ) : '';
            is( $text, $exp_content, $msg );
          };

        if ( $options{data_callback} ) {
            $check_expected->( $main::data, "$label cb got content" );
            is( $response->content, '', "$label resp content empty" );
        }
        else {
            $check_expected->( $response->content, "$label content" );
        }
    }
}

1;

# vim: et ts=4 sts=4 sw=4:
