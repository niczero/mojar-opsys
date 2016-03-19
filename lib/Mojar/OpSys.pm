package Mojar::OpSys;
use strict;

our $VERSION = 0.021;

1;
__END__

=head1 NAME

Mojar::OpSys - Pull data from the operating system.

=head1 SYNOPSIS

  use Mojar::OpSys::Ps;  # object-based access to the process list

=head1 DESCRIPTION

This is intended to be a collection of neat interfaces to the operating system,
mainly for the purpose of system monitoring/profiling.  Where it is not
practical to be cross-platform, linux will be prioritised.

=head1 SUPPORT

See L<Mojar>.

=head1 SEE ALSO

L<Unix::Lsof>, L<Unix::Mgt>, L<Unix::Uptime>, L<Proc::ProcessTable>.
