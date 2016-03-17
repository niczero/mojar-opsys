use 5.010_001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojar::OpSys',
  VERSION_FROM => 'lib/Mojar/OpSys.pm',
  ABSTRACT     => 'Operating system utilities',
  AUTHOR       => 'Nic Sandfield <niczero@cpan.org>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => 5.010001},
    resources => {
      homepage    => 'http://niczero.github.com/mojar-opsys',
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'http://github.com/niczero/mojar-opsys',
      bugtracker  => 'http://github.com/niczero/mojar-opsys/issues'
    },
    no_index => {directory => [qw(test)]}
  },
  BUILD_REQUIRES => {'Test::More' => 0},
  CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 6.3},
  PREREQ_PM => {
    Mojolicious => 4,
    Mojar => 2.011,
    'Proc::ProcessTable' => 0.5
  },
  EXE_FILES => [],
  test => {TESTS => 'test/*.t'}
);
