use strict;
use warnings;

use Test::More 0.88;
use lib 't/lib';
use TestUtils qw[monkey_patch iterate_cases];

use HTTP::Tiny::UA;
BEGIN { monkey_patch() }

srand(12345); # consistent "random" boundary creation for testing

iterate_cases( "HTTP::Tiny::UA", 't/cases', qr/^multipart/ );

done_testing;
