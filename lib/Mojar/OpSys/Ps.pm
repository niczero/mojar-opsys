package Mojar::OpSys::Ps;
use Mojo::Base -base;

our $VERSION = 0.021;

use Mojar::Util qw(been_numeric dumper);
use Mojo::Collection;
use Mojo::Util 'monkey_patch';
use Proc::ProcessTable;
use Proc::ProcessTable::Process;

monkey_patch 'Proc::ProcessTable::Process', dumper => sub {
  Mojar::Util::dumper(shift);
};
monkey_patch 'Mojo::Collection', dumper => sub {
  Mojar::Util::dumper(shift);
};

# Attributes

has broker => sub { Proc::ProcessTable->new(enable_ttys => 0) };
has constraints => sub { {} };
has table => sub { Mojo::Collection->new(@{shift->broker->table}) };

# Public methods

sub new {
  my $proto = shift;
  my $self = $proto->SUPER::new(constraints => {$proto->_param(@_)});
  %$self = %$proto if ref $proto;  # cloning
  return $self;
}

sub refresh {
  my $self = shift;
  delete $self->{table};
  $self->table;
  return $self;
}

sub all {
  my $self = shift;
  my %constraints = $self->_param(@_);
  my $list = $self->table;
  return Mojo::Collection->new(@$list) unless %constraints;

  return $list->grep(sub {
    my ($p, $ok) = ($_, 1);
    for my $c (keys %constraints) {
      undef $ok unless exists $p->{$c}
          and $self->_equals($p->{$c}, $constraints{$c});
    }
    $ok
  });
}

sub one {
  my $self = shift;
  my $list = $self->table;
  my %constraints = $self->_param(@_);
  return $list->[0] unless %constraints;

  return $list->first(sub {
    my $ok = 1;
    for my $c (keys %constraints) {
      undef $ok unless exists $_->{$c}
          and $self->_equals($_->{$c}, $constraints{$c});
    };
    $ok
  });
}

sub count { scalar @{ shift->all(@_) } }

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

Report on an individual or list of running processes.  This module stands on the
shoulders of the awesome L<Proc::ProcessTable> to provide a powerful and
convenient interface to a systems's process table.

Reliably check whether a specified process is running.  See what constraints
reliably specify your process(es).  Check how much memory and cpu each one is
consuming.  Count its instances.  Ping it or terminate it.  Check its
commandline, working directory, and status.  Derive a process tree (of
child->parent links).

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

  printf "System has been up for %u secs\n", time - $ps->one(1)->start;

=head2 count

  $c = $ps->count;
  $c = $ps->count(fname => 'httpd');

The quantity of matching processes.

=head2 exists

  $b = $ps->exists(fname => 'ntpd');

Whether (at least) one process matched.

=head2 refresh

  $c = $ps->refresh->count;

Refresh the object's view of the process table.  The table is cached in the
object to maximise performance, so this method is needed if you want a fresh
copy via the same C<Mojar::OpSys::Ps> object.

  do {
    sleep 1;
  } until $ps->refresh->exists(fname => 'nginx');  # till daemon starts

=head1 PROCESS

An individual process (such as that returned from C<one>) is a
L<Proc::ProcessTable::Process> and so there are methods and attributes for the
available fields.  Here are just the attributes common across platforms.

  cmndline    Full command line of process
  ctime       Child user + system time
  flags       Flags of process
  fname       File name
  gid         Group id of process
  pctcpu      Percent cpu used since process started
  pctmem      Percent memory			 
  pgrp        Process group
  pid         Process id
  ppid        Parent process id
  priority    Priority of process
  rss         Resident set size (bytes)
  sess        Session id
  size        Virtual memory size (bytes)
  start       Start time (seconds since the epoch)
  state       State of process
  time        User + system time                 
  uid         User id of process
  wchan       Address of current system call 

=head1 COLLECTION

A process table (such as that returned from C<all>) is a L<Mojo::Collection> and
so you can do lots of funky stuff via its methods.

  $ps->all(..)->each(sub { shift->kill(6) })

  $ram_hogs = $ps->all(..)->grep(sub { shift->rss > 1_000_000_000 })

  $wrapped = $ps->all(..)->map(sub { [shift] })

  @names = $ps->all(..)->pluck('fname')

  $biggest = $ps->all(..)->sort(sub { $_[1]->size <=> $_[0]->size })->first

=head1 PERMISSIONS

Bear in mind that not all process attributes are visible to all users.  For
example, the cwd of a process owned by root is typically unavailable (undef) to
other users.

=head1 SPEC DISCOVERY

It is fairly common that we don't know initially what attribute values are
appropriate to specify a particular process.  We may perhaps only know part of
the commandline.  However, if the process is currently running we can run a
capture manually, based on guesses, and as soon as we see its parameters it
becomes easy to choose which ones form a reliable signature.

  #!/usr/bin/env perl
  use Mojo::Base -strict;
  use Mojar::OpSys::Ps;
  printf "%s\t%s\t%s\t%s\n", qw(fname uid gid cwd);
  Mojar::OpSys::Ps->new->all(gid => 0)->grep(sub {
    shift->cmndline =~ /httpd/;
  })->each(sub {
    my $p = shift;
    printf "%s\t%u\t%u\t%s\n", $p->fname, $p->uid, $p->gid, $p->cwd;
  });

This utilises vague guesses to view candidates, one of which may be able to pin
down precise attributes which will form the production spec.

=head1 RATIONALE

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

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2014--2016, Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Proc::ProcessTable>, L<Proc::ProcessTable::Table>, L<Mojo::Collection>.
