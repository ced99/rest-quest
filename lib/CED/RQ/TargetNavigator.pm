package CED::RQ::TargetNavigator;

use Moose;
use Hash::PriorityQueue;

use CED::RQ::PathItem;

use namespace::autoclean;

extends 'CED::RQ::Navigator';

has 'target', is => 'ro', isa => 'CED::RQ::Tile', required => 1;

sub _dist {
    my ($self, $tile, $target) = @_;

    my $dist_x = abs($target->x - $tile->x);
    if ($self->map->size_x) {
        my $dist_x_wrapped = abs(($target->x + $self->map->size_x) - $tile->x);
        $dist_x = $dist_x_wrapped if $dist_x_wrapped < $dist_x;
    }
    my $dist_y = abs($target->y - $tile->y);
    if ($self->map->size_y) {
        my $dist_y_wrapped = abs(($target->y + $self->map->size_y) - $tile->y);
        $dist_y = $dist_y_wrapped if $dist_y_wrapped < $dist_y;
    }
    return $dist_x + $dist_y;
}

sub _find_path {
    my ($self) = @_;

    my $q = Hash::PriorityQueue->new();

    my %seen;
    $q->insert(
        CED::RQ::PathItem->new(
            tile => $self->map->current,
            min_possible_len => $self->_dist($self->map->current, $self->target)
        ),
        0
        );
    while (1) {
        my $item = $q->pop();
        return $item if ($item->tile->key eq $self->target->key);

        $seen{$item->tile->key} = 1;
        foreach (qw/up down left right/) {
            my $edge = $item->tile->$_;
            next unless $edge;
            next if ($edge->target->deadly);
            next if ($seen{$edge->target->key});
            my $dist =
                $self->_dist($edge->target, $self->target) + $edge->overhead;

            my $new_item = CED::RQ::PathItem->new(
                min_possible_len => $dist,
                tile => $edge->target,
                path => [@{$item->path}, $_]
                );
            $q->insert($new_item, $new_item->min_possible_len);
        }
    }
    return;
}

sub calc_move {
    my ($self) = @_;

    ### XXX optimize: don't recalc path if current and map have not changed
    my $path = $self->_find_path()->path;
    return shift @$path;
}

sub distance_to_target {
    my ($self) = @_;

    ### XXX optimize: don't recalc path if current and map have not changed
    return $self->_find_path()->min_possible_len;
}

__PACKAGE__->meta->make_immutable();

1
