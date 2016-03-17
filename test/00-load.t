use Mojo::Base -strict;
use Test::More;

use_ok 'Mojar::OpSys';
diag "Testing Mojar::OpSys $Mojar::OpSys::VERSION, Perl $], $^X";
use_ok 'Mojar::OpSys::Ps';

done_testing();
