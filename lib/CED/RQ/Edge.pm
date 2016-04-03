package CED::RQ::Edge;

use Moose;

use namespace::autoclean;

has 'source', is => 'ro', isa => 'CED::RQ::Tile', required => 1;
has 'target', is => 'ro', isa => 'CED::RQ::Tile', required => 1;

has 'steps', is => 'ro', isa => 'Int', lazy => 1, builder => '_build_steps';
has 'overhead', is => 'ro', isa => 'Int', lazy => 1,
    builder => '_build_overhead';

sub _build_steps {
    my ($self) = @_;

    return ($self->target->type eq 'mountain') ? 2 : 1;
}

sub _build_overhead {
    my ($self) = @_;

    return $self->steps - 1;
}

__PACKAGE__->meta->make_immutable();

1
