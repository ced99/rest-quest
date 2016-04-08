package CED::RQ::Navigator;

use Moose;

use namespace::autoclean;

has 'map', is => 'ro', isa => 'CED::RQ::Map', required => 1;

sub calc_move {...}

sub consume {}

__PACKAGE__->meta->make_immutable();

1;
