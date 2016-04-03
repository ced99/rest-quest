package CED::RQ::HomeNavigator;

use Moose;
use Hash::PriorityQueue;

use CED::RQ::PathItem;

use namespace::autoclean;

extends 'CED::RQ::Navigator';

has '_current_path', is => 'rw', isa => 'ArrayRef[Str]', default => sub {[]};

sub _dist {
    my ($self, $tile) = @_;

    ### XXX if map is folded -> modulo
    my $home = $self->map->home;
    return abs($home->x - $tile->x) + abs($home->y - $tile->y);
}

sub _find_path {
    my ($self) = @_;

    my $q = Hash::PriorityQueue->new();

    my %seen;
    my $home = $self->map->home;
    $q->insert(
        CED::RQ::PathItem->new(
            tile => $self->map->current,
            min_possible_len => $self->_dist($self->map->current)
        ),
        0
        );
    while (1) {
        my $item = $q->pop();
        return $item->path if ($item->tile->key eq $home->key);

        $seen{$item->tile->key} = 1;
        foreach (qw/up down left right/) {
            my $edge = $item->tile->$_;
            next unless $edge;
            next if ($edge->target->deadly);
            next if ($seen{$edge->target->key});
            my $dist = $self->_dist($edge->target) + $edge->overhead;

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

    ### XXX recalc path if map has changed

    $self->_current_path($self->_find_path()) unless (@{$self->_current_path});

    return shift @{$self->_current_path};
}

__PACKAGE__->meta->make_immutable();

1
