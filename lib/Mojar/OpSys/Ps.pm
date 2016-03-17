package Mojar::OpSys::Ps;
use Mojo::Base -base;

our $VERSION = 0.011;

use List::Util 'first';
use Mojar::Util qw(been_numeric dumper);
use Proc::ProcessTable;

# Attributes

has broker => sub { Proc::ProcessTable->new(enable_ttys => 0) };
has constraints => sub { {} };

# Public methods

sub new {
  my $proto = shift;
  my $self = $proto->SUPER::new(constraints => {$proto->_param(@_)});
  %$self = %$proto if ref $proto;  # cloning
  return $self;
}

sub all {
  my $self = shift;
  my %constraints = $self->_param(@_);
  my $list = $self->broker->table;
  return $list unless %constraints;

  @$list = grep {
    my ($p, $ok) = ($_, 1);
    for my $c (keys %constraints) {
      undef $ok unless exists $p->{$c}
          and $self->_equals($p->{$c}, $constraints{$c});
    }
    $ok
  } @$list;
  return $list;
}

sub one {
  my $self = shift;
  my $list = $self->broker->table;
  my %constraints = $self->_param(@_);
  return shift @$list unless %constraints;

  return first {
    my $ok = 1;
    for my $c (keys %constraints) {
      undef $ok unless exists $_->{$c}
          and $self->_equals($_->{$c}, $constraints{$c});
    };
    $ok
  } @$list;
}

sub count { scalar @{ shift->all(@_) } }

sub dump { dumper(shift->all(@_)) }

sub exists { !! shift->one(@_) }

sub _param {
  my $self = shift;
  unshift @_, 'pid' if @_ % 2 == 1;
  my %constraints = %{$self->constraints} if ref $self;
  return(%constraints, @_);
}

sub _equals {
  my ($self, $a, $b) = @_;
  # $b is always defined
  return 1 if not defined $a and $b eq 'undef';
  return undef unless defined $a;
  return $a == $b if been_numeric $a or been_numeric $b;
  return $a eq $b;
}

1;
__END__

=head1 NAME

Mojar::OpSys::Ps - Easily find and scrutinise running processes.

=head1 SYNOPSIS

  use Mojar::OpSys::Ps;
  my $ps = Mojar::OpSys::Ps->new(fname => 'nginx', cwd => '/var/www');
  say 'quorum' if $ps->count >= 8;
  say $_->uid, "\t", $_->rss for $ps->all;
  
=head1 DESCRIPTION

A handful of convenience methods for reporting on currently running processes.

=head1 METHODS

=head2 new

  $ps = Mojar::OpSys::Ps->new;
  $ps = Mojar::OpSys::Ps->new(gid => 50);
  $ps2 = $ps->new;

Constructor.

The implementation uses lazy evaluation, meaning the capture of the process
table is deferred till you need it, ie until you call one of the data-returning
methods below.  You can share a process table (to avoid the cost of re-capture)
by cloning: simply call C<new> on an existing object.

=head2 all

  $a = $ps->all;
  $a = $ps->all(ppid => 124);
  $a = $ps->all(fname => 'vim');

The arrayref of running processes that satisfy the given constraints.

  say $_->fname for @{$ps->all(uid => $ps->one($$)->uid)};  # all my processes
  say $_->cwd, "\t", $_->cmndline
    for @{$ps->all(uid => $my_uid, fname => 'vim')};  # my vim processes

=head2 one

  $p = $ps->one(pid => $$);
  $p = $ps->one($$);  # shorthand for the above
  $p = $ps->one(fname => 'chrome');

A single process that matched.  (An arbitrary member of the list of matching
processes.)

  printf 'System has been up for %u secs', time - $ps->one(1)->start;

=head2 count

  $c = $ps->count;
  $c = $ps->count(fname => 'httpd');

The numer of process instances matched.

=head2 exists

  $b = $ps->exists(fname => 'ntpd');

Whether one (or more) processes matched.

=head1 MOTIVATION

Monitoring a server requires checking constraints such as 'quantity of ntpd
processes is 1', 'quantity of nginx processes is at least 8', 'if box is in
standby mode, quantity of nginx processes is 0', 'no nginx process has claimed
more than 2 GB of RAM', 'no instance of daemon x is running under the root
user', etc.  I have witnessed awful sysadmin tests for these.  I actually
triggered an alarm by editing a file that had the same name as a monitored
process.  Seriously.  My hope is that this module will make it easy to avoid
such nonsense.  It becomes trivial to lock down a 'fingerprint' of the process
concerned, for example by specifying its fname, cwd, uid.  You might even grab
its cmndline and check that matches against something. 

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Proc::ProcessTable>.
