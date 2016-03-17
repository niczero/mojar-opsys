use Mojo::Base -strict;
use Test::More;

use Mojar::OpSys::Ps;

my $o = Mojar::OpSys::Ps->new;

subtest 'Raw elements' => sub {
  ok $o, 'Got an object';
  is ref($o->broker), 'Proc::ProcessTable', 'Broker has expected class';
  is ref($o->broker->table), 'ARRAY', 'Table has expected type';
  ok scalar(@{$o->broker->table}), 'Table has at least one element';
  is ref($o->broker->table->[0]), 'Proc::ProcessTable::Process',
      'Element has expected class';
};

subtest 'all' => sub {
  is ref($o->all), 'ARRAY', 'all: has expected type';
  ok scalar(@{$o->all}), 'all: has at least one element';
  is scalar(@{$o->all($$)}), 1, 'found own process';
  cmp_ok scalar(@{$o->all(ppid => 1)}), '>', 1, 'found top-level processes';
};

subtest 'one' => sub {
  is ref($o->one), 'Proc::ProcessTable::Process', 'one: has expected type';
  ok $o->one($$), 'found own process';
  like $o->one($$)->{cmndline}, qr/10-ps/, 'process matches this file';
};

subtest 'count' => sub {
  is $o->count($$), 1, 'own process';
  cmp_ok $o->count(ppid => 1), '>', 1, 'top-level processes';
};

subtest 'exists' => sub {
  ok $o->exists($$), 'own process';
  ok $o->exists($o->one($$)->ppid), 'parent process';
  ok $o->exists(ppid => 1), 'top-level processes';
};

done_testing();
