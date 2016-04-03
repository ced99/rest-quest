package CED::RQ::Navigator;

use Moose;

use namespace::autoclean;

has 'map', is => 'ro', isa => 'CED::RQ::Map', required => 1;

sub calc_move {...}

__PACKAGE__->meta->make_immutable();

1;
