package Mojar::OpSys::Ps;
use Mojo::Base -base;

our $VERSION = 0.001;

use Carp 'croak';
use List::Util 'first';
use Mojar::ClassShare 'have';
use Mojar::Util 'been_numeric';
use Proc::ProcessTable;

# Attributes

have snatcher => sub { Proc::ProcessTable->new(enable_ttys => 0) };

# Public methods

sub new {
  my $proto = shift;
  return $proto->SUPER::new($proto->param(@_));
}

sub all {
  my $self = shift;
  my $list;
  if (my $class = ref $self) {
    # object
    $list = $class->snatcher->table;
  }
  else {
    # class
    $list = $self->snatcher->table;
    $self = $self->new;
  }

  return $list unless my %constraints = $self->param(@_);

  @$list = grep {
    my ($p, $ok) = ($_, 1);
    for my $c (keys %constraints) {
      undef $ok unless exists $p->{$c}
          and $self->equals($p->{$c}, $constraints{$c});
    }
    $ok
  } @$list;
  return $list;
}

sub one {
  my $self = shift;
  my $list;
  if (my $class = ref $self) {
    # object
    $list = $class->snatcher->table;
  }
  else {
    # class
    $list = $self->snatcher->table;
    $self = $self->new;
  }

  return shift @$list unless my %constraints = $self->param(@_);

  return first {
    my $ok = 1;
    for my $c (keys %constraints) {
      undef $ok unless exists $_->{$c}
          and $self->equals($_->{$c}, $constraints{$c});
    };
    $ok
  } @$list;
}

sub count { scalar @{ shift->all(@_) } }

sub exists { !! shift->one(@_) }

sub param {
  my $self = shift;
  unshift @_, 'pid' if @_ % 2 == 1;
  return @_ unless ref $self and %$self;
  return (%$self, @_);
}

sub equals {
  my ($self, $a, $b) = @_;
  # $b is always defined
  return 1 if not defined $a and $b eq 'undef';
  return undef unless defined $a;
  return $a == $b if been_numeric $a or been_numeric $b;
  return $a eq $b;
}

1;
__END__

  my $ps = Mojar::OpSys::Ps->new;
  $ps->intersect(cmdline => 'vim', $ps->union() );

=head2 new

  $ps = Mojar::OpSys::Ps->new;
  $ps = Mojar::OpSys::Ps->new(123);
  $ps = Mojar::OpSys::Ps->new(cwd => '/root');
  $ps = $ps0->new;
  $ps = $ps0->new(..);

=head2 all

  $p = $ps->all;  # pid => 123
  $p = $ps->all(124);
  $p = $ps->all(comm => 'vim');
  $p = Mojar::OpSys::Ps->all(..);

=head2 count

