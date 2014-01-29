use strict;
use warnings;

use Test::More 0.88;
use lib 't/lib';
use TestUtils qw[monkey_patch iterate_cases];

use HTTP::Tiny::UA;
BEGIN { monkey_patch() }

iterate_cases( "HTTP::Tiny::UA", 't/cases', qr/^get/ );

done_testing;
