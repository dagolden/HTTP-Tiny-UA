use strict;
use warnings;

use Test::More;

# ABSTRACT: Simulate decoding content

use HTTP::Tiny::UA::Response;
use Test::Fatal qw( exception );

my $utf8_string = "\x{100}\x{2192}\x{2193}";
utf8::encode( my $encoded_string = $utf8_string );

isnt( $utf8_string, $encoded_string,
    "Character String and Byte String should be different" );

can_ok( 'HTTP::Tiny::UA::Response',
    qw( content decoded_content content_type content_type_params) );

subtest 'No Hints' => sub {
    my $response = HTTP::Tiny::UA::Response->new(
        success  => 1,
        protocol => 'HTTP/1.1',
        status   => 200,
        url      => 'synthetic://HTTP.Tiny.UA/300_decode_content.t',
        content  => $encoded_string,
        headers  => {},
    );
    my $e;
    is(
        $e = exception {
            is( $response->content, $encoded_string, 'content is not decoded' );
            is( $response->decoded_content,
                $encoded_string, 'encoded_content is same as content here' );
            is( $response->content_type, undef, 'no content type available' );
            is_deeply( $response->content_type_params, [], 'no content type params' );
        },
        undef,
        'All expected methods defined and not throwing exceptions'
    ) or diag $e ;
};

subtest 'simple text/plain, No Hints' => sub {
    my $response = HTTP::Tiny::UA::Response->new(
        success  => 1,
        protocol => 'HTTP/1.1',
        status   => 200,
        url      => 'synthetic://HTTP.Tiny.UA/300_decode_content.t',
        content  => $encoded_string,
        headers  => { 'content-type' => 'text/plain', }
    );
    my $e;
    is(
        $e = exception {

            is( $response->content, $encoded_string, 'content is not decoded' );
            is( $response->decoded_content,
                $encoded_string, 'encoded_content is  the same as content here' );
            is( $response->content_type, 'text/plain', 'content type is text/plain' );
            is_deeply( $response->content_type_params, [], 'no content type params' );

        },
        undef,
        'All expected methods defined and not throwing exceptions'
    ) or diag $e;
};

subtest 'text/plain;charset=utf-8' => sub {
    my $response = HTTP::Tiny::UA::Response->new(
        success  => 1,
        protocol => 'HTTP/1.1',
        status   => 200,
        url      => 'synthetic://HTTP.Tiny.UA/300_decode_content.t',
        content  => $encoded_string,
        headers  => { 'content-type' => 'text/plain;charset=utf-8', },
    );
    my $e;
    is(
        $e = exception {
            is( $response->content,         $encoded_string, 'content is not decoded' );
            is( $response->decoded_content, $utf8_string,    'encoded_content decoded as utf8' );
            is( $response->content_type,    'text/plain',    'content type is text/plain' );
            is_deeply( $response->content_type_params,
                ['charset=utf-8'], 'content type params says charset=utf8' );
        },
        undef,
        'All expected methods defined and not throwing exceptions'
    ) or diag $e;
};

done_testing;

