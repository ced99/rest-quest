package CED::RQ::PathItem;

use Moose;

use namespace::autoclean;

has 'min_possible_len', is => 'rw', isa => 'Int', required => 1;
has 'start', is => 'rw', isa => 'CED::RQ::Tile', required => 1;
has 'tile', is => 'rw', isa => 'CED::RQ::Tile', required => 1;
has 'path', is => 'ro', isa => 'ArrayRef[Str]', default => sub{ [] };

sub consume {
    my ($self, $direction) = @_;

    shift @{$self->path};
    my $edge = $self->start->$direction;
    $self->start($edge->target);
    $self->min_possible_len($self->min_possible_len - $edge->steps);
    return;
}
__PACKAGE__->meta->make_immutable();

1
