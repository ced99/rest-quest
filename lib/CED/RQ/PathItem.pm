package CED::RQ::PathItem;

use Moose;

use namespace::autoclean;

has 'min_possible_len', is => 'ro', isa => 'Int', required => 1;
has 'tile', is => 'ro', isa => 'CED::RQ::Tile', required => 1;
has 'path', is => 'ro', isa => 'ArrayRef[Str]', default => sub{ [] };

__PACKAGE__->meta->make_immutable();

1
