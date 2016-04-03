package CED::RQ::TargetNavigator;

use Moose;
use Hash::PriorityQueue;

use CED::RQ::PathItem;

use namespace::autoclean;

extends 'CED::RQ::Navigator';

has 'target', is => 'rw', isa => 'CED::RQ::Tile', trigger => \&_target_set,;

has '_current_path', is => 'rw', isa => 'ArrayRef[Str]', default => sub {[]};

sub _target_set {
    my ($self, $target, $old_target) = @_;

    $self->_current_path([])
        if ($old_target && ($target->key ne $old_target->key));
    return;
}

sub _dist {
    my ($self, $tile, $target) = @_;

    ### XXX if map is folded -> modulo
    return abs($target->x - $tile->x) + abs($target->y - $tile->y);
}

sub _find_path {
    my ($self, $target) = @_;

    my $q = Hash::PriorityQueue->new();

    my %seen;
    $q->insert(
        CED::RQ::PathItem->new(
            tile => $self->map->current,
            min_possible_len => $self->_dist($self->map->current, $target)
        ),
        0
        );
    while (1) {
        my $item = $q->pop();
        return $item if ($item->tile->key eq $target->key);

        $seen{$item->tile->key} = 1;
        foreach (qw/up down left right/) {
            my $edge = $item->tile->$_;
            next unless $edge;
            next if ($edge->target->deadly);
            next if ($seen{$edge->target->key});
            my $dist = $self->_dist($edge->target, $target) + $edge->overhead;

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

    $self->_current_path($self->_find_path($self->target)->path)
        unless (@{$self->_current_path});

    return shift @{$self->_current_path};
}

sub distance_to_target {
    my ($self, $target) = @_;

    ### XXX rewrite this class to re-use existing path
    ### XXX if $target is $self->target
    return $self->_find_path($target)->min_possible_len;
}

__PACKAGE__->meta->make_immutable();

1
