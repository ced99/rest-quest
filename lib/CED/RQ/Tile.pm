package CED::RQ::Tile;

use Moose;

use CED::RQ::Edge;

use namespace::autoclean;

has 'type', is => 'ro', isa => 'Str', required => 1;
has 'castle', is => 'ro', isa => 'Str', required => 1;
has 'treasure', is => 'rw', isa => 'Bool', required => 1;

has 'x', is => 'rw', isa => 'Int', required => 1;
has 'y', is => 'rw', isa => 'Int', required => 1;

has 'visited', is => 'rw', isa => 'Bool', default => 0;

has 'up', is => 'rw', isa => 'Maybe[CED::RQ::Edge]';
has 'down', is => 'rw', isa => 'Maybe[CED::RQ::Edge]';
has 'left', is => 'rw', isa => 'Maybe[CED::RQ::Edge]';
has 'right', is => 'rw', isa => 'Maybe[CED::RQ::Edge]';

has 'deadly', is => 'ro', isa => 'Bool', lazy => 1, builder => '_build_deadly';
has 'vision_diameter', is => 'ro', isa => 'Int', lazy => 1,
    builder => '_build_vision_diameter';

my %_vision_diameters = (
    forrest => 3,
    grass => 5,
    mountain => 7
    );

sub _build_deadly {
    my ($self) = @_;

    return ($self->type eq 'water') || ($self->castle eq 'enemy');
}

sub _build_vision_diameter {
    my ($self) = @_;

    return $_vision_diameters{$self->type} || 1;
}

sub key {
    my ($self) = @_;

    return $self->calc_key($self->x, $self->y);
}

sub calc_key {
    my ($cls, $x, $y) = @_;

    return join('/', $x, $y);
}

__PACKAGE__->meta->make_immutable();

1
