package CED::RQ::DummyNavigator;

use Moose;

use namespace::autoclean;

extends 'CED::RQ::Navigator';

has '_last_move', is => 'rw', isa => 'Str';

sub calc_move {
    my ($self) = @_;

    if ($self->_last_move) {
        $self->_last_move($self->map->reversed($self->_last_move));
    } else {
        foreach (qw/up down left right/) {
            unless ($self->map->current->$_->target->deadly) {
                $self->_last_move($_);
                last;
            }
        }
    }
    return $self->_last_move;
}

__PACKAGE__->meta->make_immutable();

1
